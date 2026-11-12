local _, G = ...
local P = {}; G.Prices = P
local function metadata(addon, key)
    local fn = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return fn and fn(addon, key) or nil
end
function P.ScopeMatches(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for _, key in ipairs({"gameFlavor", "region", "realm", "faction"}) do
        if not a[key] or a[key] ~= b[key] then return false end
    end
    return true
end
function P:ItemInfo(link)
    local fn = C_Item and C_Item.GetItemInfo or GetItemInfo
    local values = fn and {fn(link)} or {}
    if not values[1] then
        local id = G.ItemID(link)
        if id and C_Item and C_Item.RequestLoadItemDataByID then
            self.requested = self.requested or {}
            if not self.requested[id] then self.requested[id] = true; C_Item.RequestLoadItemDataByID(id) end
        end
        return {}
    end
    local binding, classID = values[14], values[12]
    -- Newly received unbound, BoE and bind-on-use loot can be sold. Quest/BoP are excluded.
    local eligible
    if binding ~= nil then eligible = (binding == 0 or binding == 2 or binding == 3) and classID ~= 12 end
    if eligible and C_Item and C_Item.IsItemBindToAccountUntilEquip then
        local ok, accountBound = pcall(C_Item.IsItemBindToAccountUntilEquip, values[2] or link)
        if not ok or issecretvalue and issecretvalue(accountBound) then eligible = nil
        elseif accountBound then eligible = false end
    end
    return {name = values[1], link = values[2], quality = values[3], icon = values[10], vendor = values[11],
        tradeEligible = eligible, bindType = binding, classID = classID}
end
function P:Imported(link, scope, now)
    local data = GrindMeterPriceData
    if type(data) ~= "table" or data.schemaVersion ~= 1 or data.priceType ~= "minimumBuyout"
        or not P.ScopeMatches(data.scope, scope) or type(data.items) ~= "table" then return nil end
    local key, id = G.ItemKey(link), G.ItemID(link)
    local fields = {}; for s in ((key or "") .. ":"):gmatch("([^:]*):") do fields[#fields + 1] = s end
    local suffix = tonumber(fields[8]) or 0
    -- Variant prices require an exact payload key. Generic prices are only used for base items.
    local row = data.items[key] or (suffix == 0 and data.items[tostring(id)] or nil)
    if type(row) ~= "table" or type(row.unitPriceCopper) ~= "number" or row.unitPriceCopper <= 0
        or type(row.observedAt) ~= "number" or row.observedAt > now or type(data.sourceName) ~= "string" then return nil end
    return {unitPriceCopper = row.unitPriceCopper, priceType = data.priceType,
        sourceName = data.sourceName, sourceVersion = data.sourceVersion, observedAt = row.observedAt,
        importedAt = data.importedAt, ageSeconds = now - row.observedAt, scope = G.Copy(data.scope)}
end
function P:Auctionator(link, scope, now)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not api or not api.GetAuctionPriceByItemLink or not api.GetAuctionAgeByItemLink then return nil end
    -- Query the public API's active client market. Forever can group the AH by
    -- regional ruleset (e.g. PvE), rather than the client's internal realm name.
    -- Never select or open another Auctionator database ourselves.
    if not P.ScopeMatches(scope, G.Client:Context()) then return nil end
    local key = G.ItemKey(link)
    local fields = {}; for field in ((key or "") .. ":"):gmatch("([^:]*):") do fields[#fields + 1] = field end
    if (tonumber(fields[8]) or 0) ~= 0 then return nil end -- no generic fallback for random suffixes
    local ok, price = pcall(api.GetAuctionPriceByItemLink, "GrindMeter", link)
    local ageOK, ageDays = pcall(api.GetAuctionAgeByItemLink, "GrindMeter", link)
    if not ok or not ageOK or type(price) ~= "number" or price <= 0 or type(ageDays) ~= "number" then return nil end
    return {unitPriceCopper = price, priceType = "minimumBuyout", sourceName = "Auctionator",
        sourceVersion = metadata("Auctionator", "Version") or "unknown", importedAt = now,
        observedAt = now - ageDays * 86400, observedAtPrecision = "day", ageDays = ageDays,
        ageSeconds = (ageDays + 1) * 86400, ageLowerSeconds = math.max(0, ageDays - 1) * 86400,
        ageUpperSeconds = (ageDays + 1) * 86400, scope = G.Copy(scope)}
end
function P:Resolve(link, scope, now)
    local value = self:ItemInfo(link)
    local ah = self:Imported(link, scope, now) or self:Auctionator(link, scope, now)
    if ah then
        local threshold = (G.Storage.settings.staleHours or 24) * 3600
        ah.stale = (ah.ageLowerSeconds or ah.ageSeconds) >= threshold
        ah.ageUncertain = not ah.stale and ah.ageUpperSeconds ~= nil and ah.ageUpperSeconds > threshold
    end
    value.ah = ah
    return value
end
local function retainKnown(replacement, old)
    if old then
        -- A temporarily unavailable API must not discard a documented last-known quote.
        if not replacement.ah then replacement.ah = old.ah end
        if not replacement.name then
            for k, v in pairs(old) do if k ~= "ah" then replacement[k] = v end end
        end
    end
    return replacement
end
function P:RefreshActiveQuotes(itemID)
    local session = G.Session.s
    if not session or self.refreshing then return false end
    self.refreshing = true
    local seen = {}
    for _, receipt in ipairs(session.lootReceipts) do
        if (not itemID or receipt.itemID == itemID) and not seen[receipt.variantKey] then
            seen[receipt.variantKey] = true
            local ok, replacement = pcall(self.Resolve, self, receipt.itemLink, session, time())
            if ok then
                session.priceSnapshot[receipt.variantKey] = retainKnown(replacement, session.priceSnapshot[receipt.variantKey])
            end
        end
    end
    self.refreshing = nil
    if G.UI then G.UI.dirty = true end
    return true
end
function P:Initialize()
    if self.subscribed then return true end
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not api or type(api.RegisterForDBUpdate) ~= "function" then return false end
    local ok = pcall(api.RegisterForDBUpdate, "GrindMeter", function() self:RefreshActiveQuotes() end)
    self.subscribed = ok
    return ok
end
function P:Snapshot(session)
    local result = {}
    for _, receipt in ipairs(session.lootReceipts) do
        if not result[receipt.variantKey] then
            local replacement = self:Resolve(receipt.itemLink, session, time())
            if session == G.Session.s then replacement = retainKnown(replacement, session.priceSnapshot[receipt.variantKey]) end
            result[receipt.variantKey] = replacement
        end
    end
    return result
end
function P:FillItemData(session)
    -- Static item metadata can load late. Never replace an old session's AH quote with a current quote.
    for _, receipt in ipairs(session.lootReceipts or {}) do
        local price = session.priceSnapshot[receipt.variantKey]
        if not price or not price.name then
            local item = self:ItemInfo(receipt.itemLink)
            if item.name then
                price = price or {}; session.priceSnapshot[receipt.variantKey] = price
                for k, v in pairs(item) do price[k] = v end
            end
        end
    end
end
