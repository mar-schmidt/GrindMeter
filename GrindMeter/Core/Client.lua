local _, G = ...
local C = {events = {}, errors = {}}; G.Client = C
local function safe(value) return not issecretvalue or not issecretvalue(value) end
local function api(name) return type(_G[name]) == "function" end
function C:Context()
    local version, build, buildDate, interface = GetBuildInfo()
    local name, realm = UnitFullName("player")
    realm = realm or GetRealmName()
    local region = GetCurrentRegion and GetCurrentRegion() or nil
    local regions = {[1] = "US", [2] = "KR", [3] = "EU", [4] = "TW", [5] = "CN"}
    local faction = UnitFactionGroup("player")
    local context = {characterKey = (name or "unknown") .. "-" .. realm,
        gameFlavor = interface >= 16000 and interface < 17000 and "forever" or "unsupported",
        region = regions[region] or "unknown", realm = GetRealmName(), faction = faction or "unknown",
        clientVersion = version, clientBuild = build, clientBuildDate = buildDate, interface = interface, locale = GetLocale(),
        levelStart = UnitLevel("player"), restedInfo = GetXPExhaustion and GetXPExhaustion() or 0,
        groupInfo = IsInGroup() and "group" or "solo"}
    context.killAvailable = self.combatRegistered and api("CombatLogGetCurrentEventInfo") and not self:Restricted()
    context.xpAvailable = G.Parser.xp and #G.Parser.xp > 0 or false
    context.xpZeroExpected = (IsXPUserDisabled and IsXPUserDisabled()) or (UnitXPMax("player") == 0)
    context.lootSourceAvailable = api("GetLootSourceInfo")
    return context
end
function C:Restricted()
    if C_CombatLog and C_CombatLog.IsCombatLogRestricted then
        local ok, restricted = pcall(C_CombatLog.IsCombatLogRestricted)
        return not ok or not safe(restricted) or restricted == true
    end
    return false
end
function C:Selection()
    local guid = UnitGUID("target")
    if not safe(guid) then return nil end
    local id = G.NpcID(guid)
    if not id or UnitIsPlayer("target") or not UnitCanAttack("player", "target") then return nil end
    local name = UnitName("target")
    if not safe(name) then return nil end
    return {npcID = id, name = name or tostring(id), mapID = C_Map and C_Map.GetBestMapForUnit("player"),
        zoneName = GetZoneText()}
end
function C:CaptureLoot()
    if not api("GetNumLootItems") then return {} end
    local slots = {}
    for index = 1, GetNumLootItems() do
        local link = GetLootSlotLink(index)
        if not safe(link) then link = nil end
        local _, _, quantity = GetLootSlotInfo(index)
        local sources, values = {}, api("GetLootSourceInfo") and {GetLootSourceInfo(index)} or {}
        -- Legacy source tuples: GUID, quantity, GUID, quantity, ...; no leading count.
        for i = 1, #values, 2 do
            if safe(values[i]) and type(values[i]) == "string" then
                sources[#sources + 1] = {guid = values[i], quantity = safe(values[i + 1]) and values[i + 1] or nil}
            end
        end
        local kind = GetLootSlotType and GetLootSlotType(index)
        slots[index] = {index = index, itemLink = link, variantKey = G.ItemKey(link),
            quantity = safe(quantity) and quantity or 1, kind = kind == (LOOT_SLOT_MONEY or 1) and "money" or "item", sources = sources}
    end
    return slots
end
function C:Dispatch(event, ...)
    self.events[event] = (self.events[event] or 0) + 1
    local now = GetTime()
    if event == "PLAYER_LOGOUT" then G.Session:Checkpoint(now); return end
    if event == "GROUP_ROSTER_UPDATE" or event == "UNIT_PET" then G.Trackers:UpdateRoster(); return end
    if event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        local id = ...; if G.Prices.requested then G.Prices.requested[id] = nil end
        G.UI.dirty = true; return
    end
    if event == "PLAYER_ENTERING_WORLD" then G.Trackers:UpdateRoster(); return end
    if not G.Session.s then return end
    local T = G.Trackers
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if self:Restricted() then G.Session.s.killAvailable = false; T:Diagnostic("combatRestricted"); return end
        local data = {CombatLogGetCurrentEventInfo()}
        for _, i in ipairs({2, 4, 8, 9}) do if not safe(data[i]) then G.Session.s.killAvailable = false; return end end
        T:Combat(data[2], data[4], data[8], data[9], now)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local message = ...; if safe(message) then T:XP(message, select(11, ...), now) end
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        T:XPDelta(UnitXP("player"), UnitXPMax("player"), UnitLevel("player"), now)
    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        if G.Session:Collecting(now) then
            local _, isFromItem = ...
            T:OpenLoot(self:CaptureLoot(), now, isFromItem, T.gatherUntil and T.gatherUntil >= now)
        end
    elseif event == "LOOT_SLOT_CLEARED" then T:ClearSlot(...)
    elseif event == "LOOT_CLOSED" then T:CloseLoot(now)
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        if safe(message) then
            local link, quantity = G.Parser:Loot(message)
            if link then T:Receipt(link, quantity, select(11, ...), now) end
        end
    elseif event == "CHAT_MSG_MONEY" then
        local message = ...
        if safe(message) then
            local amount = G.Parser:Money(message)
            if amount then T:Money(amount, select(11, ...), now)
            else T:Diagnostic("unparsedMoney"); if G.Session.s then G.Session.s.moneyUnavailable = true end end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        -- Rank variants of gathering spells are treated as professions, never ordinary mob loot.
        if unit == "player" and ({[8613] = true, [8617] = true, [8618] = true, [10768] = true,
            [2575] = true, [2576] = true, [3564] = true, [10248] = true,
            [2366] = true, [2368] = true, [3570] = true, [11993] = true,
            [1804] = true, [13262] = true, [921] = true})[spellID] then T.gatherUntil = now + 5 end
    end
    if G.UI then G.UI.dirty = true end
end
function C:Register(frame)
    local names = {"PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "GROUP_ROSTER_UPDATE", "UNIT_PET",
        "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_LOOT", "CHAT_MSG_MONEY", "LOOT_READY", "LOOT_OPENED",
        "LOOT_SLOT_CLEARED", "LOOT_CLOSED", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "UNIT_SPELLCAST_SUCCEEDED",
        "COMBAT_LOG_EVENT_UNFILTERED"}
    for _, event in ipairs(names) do
        local ok = pcall(frame.RegisterEvent, frame, event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then self.combatRegistered = ok end
        if not ok then self.errors[event] = "registration-unavailable" end
    end
end
function C:Diagnostics()
    local context = self:Context()
    local lines = {"GrindMeter " .. G.version, "Client: " .. context.clientVersion .. "." .. context.clientBuild,
        "Interface: " .. context.interface .. " | locale: " .. context.locale,
        "Scope: " .. context.gameFlavor .. " / " .. context.region .. " / " .. context.realm .. " / " .. context.faction,
        "Combat API: " .. tostring(api("CombatLogGetCurrentEventInfo")), "Restricted: " .. tostring(self:Restricted()),
        "Loot source API: " .. tostring(api("GetLootSourceInfo")), "XP formats: " .. #G.Parser.xp,
        "Auctionator API v1: " .. tostring(Auctionator and Auctionator.API and Auctionator.API.v1 ~= nil or false),
        "In-game validation: pending (synthetic tests are separate).", "", "Event counts:"}
    local keys = {}; for k in pairs(self.events) do keys[#keys + 1] = k end; table.sort(keys)
    for _, k in ipairs(keys) do lines[#lines + 1] = k .. " = " .. self.events[k] end
    for k, value in pairs(self.errors) do lines[#lines + 1] = k .. " = " .. value end
    local s = G.Session.s or G.Session.last
    if s then
        lines[#lines + 1] = ""; lines[#lines + 1] = "Session diagnostics:"
        for k, v in pairs(s.diagnosticsSummary) do lines[#lines + 1] = k .. " = " .. v end
    end
    return table.concat(lines, "\n")
end
