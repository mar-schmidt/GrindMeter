local _, G = ...
local S = {}; G.Session = S
function S:Counter(npcID, name)
    local s = self.s
    local counter = s.countersByNpcID[npcID]
    if not counter then
        counter = {name = name or tostring(npcID), kills = 0, xp = 0, xpKills = 0}
        s.countersByNpcID[npcID] = counter
    elseif name then counter.name = name end
    return counter
end
function S:Start(selection, context, now, epoch)
    if self.s then return false, "alreadyRunning" end
    if not selection or not selection.npcID then return false, "noTarget" end
    local settings = G.Storage.settings
    local session = G.Copy(context)
    session.id = tostring(epoch) .. "-" .. tostring(math.floor(now * 1000))
    session.schemaVersion = G.schema; session.addonVersion = G.version
    session.selectedNpcID = selection.npcID; session.selectedName = selection.name
    session.mapID = selection.mapID; session.zoneName = selection.zoneName
    session.startedAt = epoch; session.measuredSeconds = 0; session.pausedSeconds = 0
    session.duration = settings.duration; session.state = "running"; session.fee = settings.fee
    session.countersByNpcID = {}; session.killRecords = {}; session.killOrder = {}
    session.lootReceipts = {}; session.coinsByNpcID = {}; session.priceSnapshot = {}
    session.unattributedXP = 0; session.unattributedLoot = 0; session.unattributedMoney = 0
    session.allXPDelta = 0; session.diagnosticsSummary = {}; session.bodyObservations = {}
    session.catalogVersion = G.Catalog.version; session.collectionEpoch = 1
    self.s = session; self.anchor = now; self.pauseAnchor = nil; self.last = nil
    self:Counter(selection.npcID, selection.name)
    G.Storage.character.active = session
    if G.Trackers then G.Trackers:Reset() end
    return true
end
function S:Tick(now)
    local session = self.s
    if not session then return end
    if session.state == "running" then
        local delta = math.max(0, now - self.anchor)
        self.anchor = now
        if session.duration > 0 then delta = math.min(delta, session.duration - session.measuredSeconds) end
        session.measuredSeconds = session.measuredSeconds + delta
        if session.duration > 0 and session.measuredSeconds >= session.duration then self:Stop(now, time(), "timeout"); return end
    elseif self.pauseAnchor then
        session.pausedSeconds = session.pausedSeconds + math.max(0, now - self.pauseAnchor)
        self.pauseAnchor = now
    end
end
function S:Collecting(now)
    self:Tick(now)
    return self.s and self.s.state == "running" or false
end
function S:Pause(now)
    self:Tick(now)
    if not self.s or self.s.state ~= "running" then return end
    if G.Trackers then G.Trackers:FlushXP(now, true) end
    self.s.state = "paused"; self.pauseAnchor = now
    self.s.collectionEpoch = self.s.collectionEpoch + 1
    if G.Trackers then G.Trackers:ResetTransient() end
end
function S:Resume(now)
    self:Tick(now)
    if not self.s or self.s.state ~= "paused" then return end
    self.s.state = "running"; self.s.collectionEpoch = self.s.collectionEpoch + 1
    self.anchor = now; self.pauseAnchor = nil
    if G.Trackers then G.Trackers:ResetTransient() end
end
function S:Stop(now, epoch, reason)
    if not self.s or self.stopping then return end
    self.stopping = true
    local session = self.s
    if reason ~= "timeout" then self:Tick(now) end
    if G.Trackers then G.Trackers:FlushXP(now, true) end
    session.endedAt = epoch; session.state = "finished"; session.stopReason = reason or "manual"
    session.levelEnd = G.Client and UnitLevel("player") or session.levelStart
    session.priceSnapshot = G.Prices:Snapshot(session)
    G.Catalog:Learn(session)
    -- Persist summaries, not a raw combat log. Active attribution caches are discarded.
    session.killRecords = nil; session.killOrder = nil; session.bodyObservations = nil
    self.last = session; self.s = nil; self.anchor = nil; self.pauseAnchor = nil
    G.Storage:Add(session)
    if G.Trackers then G.Trackers:ResetTransient() end
    self.stopping = nil
    if self.OnStopped then self.OnStopped(session) end
end
function S:Checkpoint(now)
    if self.s then self:Pause(now) end
end
function S:Restore(now)
    local session = G.Storage.character.active
    if not session then return end
    session.state = "paused"; session.recovered = true
    session.collectionEpoch = (session.collectionEpoch or 0) + 1
    session.killRecords = {}; session.killOrder = {}; session.bodyObservations = session.bodyObservations or {}
    self.s = session; self.anchor = now; self.pauseAnchor = now
    if G.Trackers then G.Trackers:Reset() end
end
