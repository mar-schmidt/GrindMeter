local _, G = ...
local T = {}; G.Trackers = T
local MAX_KILLS, MAX_RECEIPTS = 4096, 8192
function T:ResetTransient()
    self.pendingXP = {}; self.recentKills = {}; self.windows = {}; self.window = nil; self.gatherUntil = nil
    self.seenLines = {}; self.lineOrder = {}; self.receiptSequence = 0
    self.xpCheck = nil
    self.receiptGroups = nil
end
function T:Reset()
    self:ResetTransient(); self.observedBodies = {}; self.roster = {}
    if G.Client then self:UpdateRoster() end
end
function T:Diagnostic(key)
    local s = G.Session.s
    if s then s.diagnosticsSummary[key] = (s.diagnosticsSummary[key] or 0) + 1 end
end
function T:Unique(channel, lineID)
    if type(lineID) ~= "number" or lineID <= 0 then return true end
    local key = channel .. ":" .. lineID
    if self.seenLines[key] then return false end
    self.seenLines[key] = true; self.lineOrder[#self.lineOrder + 1] = key
    if #self.lineOrder > 1024 then self.seenLines[table.remove(self.lineOrder, 1)] = nil end
    return true
end
function T:UpdateRoster()
    local roster = {}
    local function add(unit)
        local guid = UnitGUID(unit)
        if (not issecretvalue or not issecretvalue(guid)) and type(guid) == "string" then roster[guid] = true end
    end
    add("player"); add("pet"); add("vehicle")
    for i = 1, 4 do add("party" .. i); add("partypet" .. i) end
    for i = 1, 40 do add("raid" .. i); add("raidpet" .. i) end
    local signature = {}; for guid in pairs(roster) do signature[#signature + 1] = guid end
    table.sort(signature); signature = table.concat(signature, ",")
    local s = G.Session.s
    if s and self.rosterSignature and self.rosterSignature ~= signature then s.groupChanged = true end
    self.roster = roster; self.rosterSignature = signature
end
function T:Credit(guid, name, sourceGUID, now, evidence)
    if not G.Session:Collecting(now) then return false end
    local s = G.Session.s; local npcID = G.NpcID(guid)
    if not npcID then return false end
    if evidence ~= "PARTY_KILL" or not self.roster[sourceGUID] then
        self:Diagnostic("unconfirmedCredit"); return false
    end
    if s.killRecords[guid] then return false end
    local record = {creatureGUID = guid, npcID = npcID, name = name, eventTime = now,
        creditEvidence = evidence, confidence = "confirmed", epoch = s.collectionEpoch}
    s.killRecords[guid] = record; s.killOrder[#s.killOrder + 1] = guid
    if #s.killOrder > MAX_KILLS then
        local expired = table.remove(s.killOrder, 1)
        if G.Session:IsContinuous(s) then
            local old = s.killRecords[expired]
            local observations = s.bodyObservations[old.npcID]
            if observations and observations[expired] then
                G.Catalog:Learn({bodyObservations = {[old.npcID] = {[expired] = observations[expired]}}, endedAt = time()})
                observations[expired] = nil
            end
            self.observedBodies[expired] = nil
        end
        s.killRecords[expired] = nil
    end
    self.recentKills[#self.recentKills + 1] = record
    if #self.recentKills > 100 then table.remove(self.recentKills, 1) end
    G.Session:Counter(npcID, name).kills = G.Session:Counter(npcID, name).kills + 1
    s.killAvailable = true; self:Diagnostic("confirmedKills")
    return true
end
function T:XP(message, lineID, now)
    if not G.Session:Collecting(now) or not self:Unique("xp", lineID) then return end
    local parsed = G.Parser:XP(message)
    if not parsed then self:Diagnostic("unparsedXP"); G.Session.s.xpAvailable = false; return end
    if parsed.unclassified then self:Diagnostic("nonMobXP"); return end
    parsed.eventTime = now; parsed.epoch = G.Session.s.collectionEpoch
    self.pendingXP[#self.pendingXP + 1] = parsed
end
function T:FlushXP(now, force)
    local s = G.Session.s
    if not s then return end
    local keep = {}
    for _, xp in ipairs(self.pendingXP or {}) do
        if force or now - xp.eventTime >= 1.25 then
            local npcID, candidate, ambiguous
            for _, kill in ipairs(self.recentKills) do
                if kill.epoch == xp.epoch and not kill.xpConsumed and kill.name == xp.name
                    and math.abs(kill.eventTime - xp.eventTime) <= 1.25 then
                    if npcID and npcID ~= kill.npcID then ambiguous = true end
                    npcID = kill.npcID; candidate = kill
                end
            end
            if npcID and not ambiguous then
                local counter = G.Session:Counter(npcID)
                counter.xp = counter.xp + xp.amount; counter.xpKills = counter.xpKills + 1
                candidate.xpConsumed = true
            else s.unattributedXP = s.unattributedXP + xp.amount; self:Diagnostic("ambiguousXP") end
        else keep[#keep + 1] = xp end
    end
    self.pendingXP = keep
end
function T:XPDelta(currentXP, maximum, level, now)
    if not G.Session:Collecting(now) then self.xpCheck = {xp = currentXP, max = maximum, level = level}; return end
    local old = self.xpCheck
    if old then
        local delta
        if level == old.level then delta = currentXP - old.xp
        elseif level == old.level + 1 then delta = old.max - old.xp + currentXP end
        if delta and delta >= 0 then G.Session.s.allXPDelta = G.Session.s.allXPDelta + delta end
    end
    self.xpCheck = {xp = currentXP, max = maximum, level = level}
end
function T:OpenLoot(slots, now, isFromItem, gathering)
    if not G.Session:Collecting(now) then return end
    -- LOOT_READY and LOOT_OPENED commonly describe the same window.
    if self.window and not self.window.closedAt then
        if isFromItem then self.window.isFromItem = true end
        if gathering then self.window.gathering = true end
        for index, slot in pairs(slots) do
            if not self.window.slots[index] then
                local copy = G.Copy(slot); copy.remaining = copy.quantity or 1
                self.window.slots[index] = copy
                for _, source in ipairs(copy.sources or {}) do self.window.bodyGUIDs[source.guid] = true end
            end
        end
        return self.window
    end
    local s = G.Session.s
    local w = {slots = G.Copy(slots), openedAt = now, epoch = s.collectionEpoch, isFromItem = isFromItem,
        gathering = gathering, bodyGUIDs = {}, hadReceipt = false}
    for _, slot in pairs(w.slots) do
        slot.remaining = slot.quantity or 1
        for _, source in ipairs(slot.sources or {}) do w.bodyGUIDs[source.guid] = true end
    end
    -- A second, completed corpse-loot window could be skinning; don't silently treat it as normal loot.
    for guid in pairs(w.bodyGUIDs) do
        if self.observedBodies[guid] then w.reopenedCompleted = true end
    end
    self.window = w; self.windows[#self.windows + 1] = w
    while #self.windows > 6 do table.remove(self.windows, 1) end
    return w
end
function T:Source(slot, window)
    local s = G.Session.s
    if not s or window.epoch ~= s.collectionEpoch or window.isFromItem or window.gathering or window.reopenedCompleted then return nil end
    local npcID, guids, ambiguous = nil, {}, false
    for _, source in ipairs(slot.sources or {}) do
        local kill = s.killRecords[source.guid]
        if not kill or kill.epoch ~= s.collectionEpoch then ambiguous = true
        else
            if npcID and npcID ~= kill.npcID then ambiguous = true end
            npcID = kill.npcID; guids[#guids + 1] = source.guid
        end
    end
    if ambiguous or #guids == 0 then return nil end
    return npcID, guids
end
function T:FindSlot(key, quantity, now, money)
    local candidates = {}
    for _, w in ipairs(self.windows) do
        if w.epoch == G.Session.s.collectionEpoch and (not w.closedAt or now - w.closedAt <= 1) then
            for _, slot in pairs(w.slots) do
                if (money and slot.kind == "money" or not money and slot.variantKey == key) and slot.remaining >= quantity then
                    candidates[#candidates + 1] = {slot = slot, window = w}
                end
            end
        end
    end
    -- If two open/recent contexts match, source attribution is unresolved.
    if #candidates == 1 then return candidates[1].slot, candidates[1].window end
end
function T:Receipt(link, quantity, lineID, now)
    if not G.Session:Collecting(now) or not self:Unique("loot", lineID) then return end
    local s = G.Session.s; local key, itemID = G.ItemKey(link), G.ItemID(link)
    if not key or not itemID or type(quantity) ~= "number" or quantity <= 0 then return end
    local slot, window = self:FindSlot(key, quantity, now)
    local npcID, guids
    if slot then
        npcID, guids = self:Source(slot, window)
        slot.remaining = slot.remaining - quantity; window.hadReceipt = true
    end
    self.receiptSequence = self.receiptSequence + 1
    local receipt = {receiptID = s.id .. ":" .. s.collectionEpoch .. ":" .. self.receiptSequence,
        eventTime = now, itemID = itemID, itemLink = link, variantKey = key, quantity = quantity,
        sourceGUIDs = guids or {}, sourceNpcID = npcID, category = npcID and "normal" or "unclassified",
        attributionStatus = npcID and "confirmed" or "unknown"}
    local groupKey, previous
    if G.Session:IsContinuous(s) then
        if not self.receiptGroups then
            self.receiptGroups = {}
            for _, row in ipairs(s.lootReceipts) do
                self.receiptGroups[row.variantKey .. ":" .. (row.sourceNpcID or "unknown") .. ":" .. row.category] = row
            end
        end
        groupKey = key .. ":" .. (npcID or "unknown") .. ":" .. receipt.category
        previous = self.receiptGroups[groupKey]
        receipt.sourceGUIDs = {}; receipt.aggregated = true; receipt.receiptCount = 1
    end
    if previous then
        previous.quantity = previous.quantity + quantity
        previous.receiptCount = (previous.receiptCount or 1) + 1; previous.lastEventTime = now
    else
        if #s.lootReceipts >= MAX_RECEIPTS then self:Diagnostic("receiptLimit"); G.Session:Stop(now, time(), "receiptLimit"); return end
        s.lootReceipts[#s.lootReceipts + 1] = receipt
        if groupKey then self.receiptGroups[groupKey] = receipt end
    end
    if not npcID then s.unattributedLoot = s.unattributedLoot + quantity end
    if not s.priceSnapshot[key] then s.priceSnapshot[key] = G.Prices:Resolve(link, s, time()) end
    if npcID and #guids == 1 then
        s.bodyObservations[npcID] = s.bodyObservations[npcID] or {}
        local bodies = s.bodyObservations[npcID]
        local body = bodies[guids[1]] or {items = {}}; bodies[guids[1]] = body
        local item = body.items[key] or {itemID = itemID, itemLink = link, quantity = 0}
        body.items[key] = item; item.quantity = item.quantity + quantity
    end
    self:Diagnostic("receivedItems")
end
function T:Money(copper, lineID, now)
    if not G.Session:Collecting(now) or not self:Unique("money", lineID) then return end
    local s = G.Session.s
    local slot, window = self:FindSlot(nil, 1, now, true)
    local npcID
    -- In groups, a coin receipt can be a split from another corpse: context alone is insufficient.
    if slot and not IsInGroup() then
        npcID = self:Source(slot, window); slot.remaining = 0; window.hadReceipt = true
    end
    if npcID then s.coinsByNpcID[npcID] = (s.coinsByNpcID[npcID] or 0) + copper
    else s.unattributedMoney = s.unattributedMoney + copper end
end
function T:ClearSlot(index)
    if self.window and self.window.slots[index] then self.window.slots[index].cleared = true end
end
function T:CloseLoot(now)
    local w, s = self.window, G.Session.s
    if not w then return end
    w.closedAt = now
    if not G.Session:Collecting(now) then self.window = nil; return end
    if s and s.state == "running" and not w.gathering and not w.isFromItem and not w.reopenedCompleted and not IsInGroup() then
        local complete, guid, count, npcID = true, nil, 0, nil
        for id in pairs(w.bodyGUIDs) do guid = id; count = count + 1 end
        for _, slot in pairs(w.slots) do
            if not slot.cleared then complete = false end
            local source = self:Source(slot, w)
            if not source then complete = false end
            if npcID and source ~= npcID then complete = false end
            npcID = source
        end
        if complete and count == 1 and npcID then
            self.observedBodies[guid] = true
            s.observedBodyCount = (s.observedBodyCount or 0) + 1
            s.bodyObservations[npcID] = s.bodyObservations[npcID] or {}
            local body = s.bodyObservations[npcID][guid] or {items = {}}
            s.bodyObservations[npcID][guid] = body
            -- Finalized later, after possible chat confirmations following LOOT_CLOSED.
            body.qualified = true
        end
    end
    self.window = nil
end
