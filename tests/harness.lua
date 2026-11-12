-- Synthetic WoW 5.1 harness. This is not an in-game compatibility test.
local H = {clock = 0, frames = {}, items = {}, group = false, level = 38, xp = 100, xpMax = 10000}
function H.guid(id, individual) return "Creature-0-1-1-1-" .. id .. "-" .. (individual or "000001") end
function H.link(id, suffix)
    return "|cff1eff00|Hitem:" .. id .. ":0:0:0:0:0:" .. (suffix or 0) .. ":0:38:0:0|h[Test Item " .. id .. "]|h|r"
end
local Frame = {}; Frame.__index = Frame
local function new(kind, name, parent)
    local f = setmetatable({kind = kind, name = name, parent = parent, shown = true, width = 0, height = 0, scripts = {}, enabled = true}, Frame)
    H.frames[#H.frames + 1] = f; return f
end
function Frame:SetSize(w, h) assert(type(w) == "number" and type(h) == "number"); self.width = w; self.height = h end
function Frame:SetWidth(w) assert(type(w) == "number"); self.width = w end
function Frame:SetHeight(h) self.height = h end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
function Frame:GetParent() return self.parent end
function Frame:SetPoint(point, relative, relativePoint, x, y)
    if type(relative) == "number" then x, y, relative, relativePoint = relative, relativePoint, self.parent, point end
    self.anchor = {point, relative or self.parent, relativePoint or point, x or 0, y or 0}
end
function Frame:GetPoint() return unpack(self.anchor) end
function Frame:ClearAllPoints() self.anchor = nil end
function Frame:SetAllPoints(relative) self.fillParent = relative or self.parent end
function Frame:CreateTexture(name) return new("Texture", name, self) end
function Frame:CreateFontString(name) return new("FontString", name, self) end
function Frame:SetText(text)
    self.text = tostring(text or ""); if self.fontString then self.fontString:SetText(text) end
    if self.kind == "GameTooltip" then self.lines = {self.text} end
end
function Frame:ClearLines() self.lines = {} end
function Frame:AddLine(text) self.lines[#self.lines + 1] = text end
function Frame:AddDoubleLine(left, right) self.lines[#self.lines + 1] = left .. ": " .. right end
function Frame:SetOwner(owner) self.owner = owner end
function Frame:IsOwned(owner) return self.owner == owner end
function Frame:GetText() return self.text or "" end
function Frame:SetFontString(font) self.fontString = font end
function Frame:SetFont(path, size) self.fontSize = size end
function Frame:SetTextColor(...) self.textColor = {...} end
function Frame:SetColorTexture(...) self.textureColor = {...} end
function Frame:SetBackdropColor(...) self.bg = {...} end
function Frame:SetBackdropBorderColor(...) self.border = {...} end
function Frame:SetBackdrop(backdrop) self.backdrop = backdrop end
function Frame:SetTexture(texture) self.texture = texture end
function Frame:SetFontObject() self.fontSize = 12 end
function Frame:SetJustifyH(value) self.align = value end
function Frame:SetJustifyV() end
function Frame:SetWordWrap() end
function Frame:SetAlpha(value) self.alpha = value end
function Frame:SetFrameStrata(value) self.strata = value end
function Frame:SetFrameLevel(value) self.frameLevel = value end
function Frame:GetFrameLevel() return self.frameLevel or 1 end
function Frame:SetScale(scale) self.scale = scale end
function Frame:GetEffectiveScale() return self.scale or 1 end
function Frame:SetMovable() end
function Frame:SetClampedToScreen() end
function Frame:EnableMouse() end
function Frame:RegisterForDrag() end
function Frame:RegisterForClicks() end
function Frame:SetHighlightTexture() end
function Frame:SetEnabled(value) self.enabled = value end
function Frame:SetAutoFocus() end
function Frame:SetNumeric() end
function Frame:SetMultiLine() end
function Frame:SetFocus() end
function Frame:ClearFocus() end
function Frame:HighlightText() end
function Frame:SetScrollChild(child) self.scrollChild = child end
function Frame:SetScript(event, fn) self.scripts[event] = fn end
function Frame:GetScript(event) return self.scripts[event] end
function Frame:RegisterEvent(event)
    H.registrationAttempts[#H.registrationAttempts + 1] = event
    if H.blockedEvents[event] then
        -- Blizzard can emit ADDON_ACTION_FORBIDDEN without throwing a Lua error.
        H.forbiddenAttempts = H.forbiddenAttempts + 1
        return true
    end
    self.events = self.events or {}; self.events[event] = true
end
function Frame:StartMoving() end
function Frame:StopMovingOrSizing() end
function Frame:Show()
    local changed = not self.shown; self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Frame:Hide()
    local changed = self.shown; self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:SetShown(value) if value then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function Frame:GetCenter() return 1000, 100 end
function Frame:Click(button) if self.enabled and self.scripts.OnClick then self.scripts.OnClick(self, button or "LeftButton") end end
function H.setup(loadUI)
    H.clock = 0; H.frames = {}; H.items = {}; H.group = false; H.level = 38; H.xp = 100; H.xpMax = 10000
    H.target = nil; H.requests = 0; H.inserted = nil; H.chat = nil; H.reference = nil
    H.forbiddenAttempts = 0; H.registrationAttempts = {}
    H.blockedEvents = {COMBAT_LOG_EVENT_UNFILTERED = true, COMBAT_LOG_EVENT = true}
    GrindMeterDB = nil; GrindMeterPriceData = nil; Auctionator = nil
    strsplit = function(separator, text)
        local values = {}; for value in (text .. separator):gmatch("(.-)" .. separator) do values[#values + 1] = value end
        return unpack(values)
    end
    time = function() return 1794470000 + math.floor(H.clock) end
    date = os.date; GetTime = function() return H.clock end
    CreateFrame = new
    UIParent = new("Frame", "UIParent"); UIParent:SetSize(1440, 1000)
    Minimap = new("Frame", "Minimap", UIParent); Minimap:SetSize(140, 140)
    GameTooltip = setmetatable({}, {__index = function() return function() end end})
    DEFAULT_CHAT_FRAME = {AddMessage = function() end}; ChatFontNormal = {}; ItemRefTooltip = {}
    STANDARD_TEXT_FONT = "Fonts/FRIZQT__.TTF"; SlashCmdList = {}
    ITEM_QUALITY_COLORS = {[1] = {r = 1, g = 1, b = 1}, [2] = {r = .2, g = 1, b = .2}}
    GetBuildInfo = function() return "1.60.1", "70888", "Nov 12 2026", 16001 end
    UnitFullName = function() return "Tester", "Normal" end
    GetRealmName = function() return "Normal" end
    GetCurrentRegion = function() return 3 end
    UnitFactionGroup = function() return "Alliance" end
    GetLocale = function() return "enUS" end
    UnitLevel = function() return H.level end
    UnitXP = function() return H.xp end
    UnitXPMax = function() return H.xpMax end
    GetXPExhaustion = function() return 4200 end
    IsInGroup = function() return H.group end
    InCombatLockdown = function() return false end
    IsLoggedIn = function() return true end
    UnitGUID = function(unit)
        if unit == "player" then return "Player-1-Tester" end
        if unit == "pet" then return "Pet-1-Tester" end
        if unit == "target" then return H.target or H.guid(259055) end
    end
    UnitName = function(unit) return unit == "target" and "Wildplains Huntress" or "Tester" end
    UnitIsPlayer = function() return false end
    UnitCanAttack = function() return true end
    GetZoneText = function() return "Riverglades" end
    C_Map = {GetBestMapForUnit = function() return 999 end}
    C_CombatLog = {IsCombatLogRestricted = function() return false end}
    C_AddOns = {GetAddOnMetadata = function() return "345" end}
    CombatLogGetCurrentEventInfo = nil -- unavailable in the target Forever client
    issecretvalue = function() return false end
    C_Item = {GetItemInfo = function(link)
        local data = H.items[tonumber(link:match("item:(%d+)"))]
        if not data then return end
        return data.name or "Test Item", link, data.quality or 2, 38, 1, "Trade Goods", "Other", 20, "", 12345, data.vendor, data.class or 7, 0, data.bind or 0
    end, RequestLoadItemDataByID = function() H.requests = (H.requests or 0) + 1 end}
    ChatEdit_InsertLink = function(link) H.inserted = link; return false end
    ChatFrame_OpenChat = function(link) H.chat = link end
    IsModifiedClick = function() return false end
    HandleModifiedItemClick = function() return false end
    SetItemRef = function(link) H.reference = link end
    COMBATLOG_XPGAIN_FIRSTPERSON = "%s dies, you gain %d experience."
    COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = "%s dies, you gain %d experience. (+%d group bonus)"
    COMBATLOG_XPGAIN_EXHAUSTION1 = "%s dies, you gain %d experience. (+%d exp Rested bonus)"
    COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = "You gain %d experience."
    LOOT_ITEM_SELF = "You receive loot: %s."
    LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
    LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
    LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %sx%d."
    YOU_LOOT_MONEY = "You loot %s."
    LOOT_MONEY_SPLIT = "Your share of the loot is %s."
    GOLD_AMOUNT = "%d Gold"; SILVER_AMOUNT = "%d Silver"; COPPER_AMOUNT = "%d Copper"
    local G = {}
    for line in io.lines("GrindMeter/GrindMeter.toc") do
        if line:match("%.lua$") and (loadUI or not line:match("^UI/") and not line:match("Bootstrap")) then
            local fn, err = loadfile("GrindMeter/" .. line); assert(fn, err); fn("GrindMeter", G)
        end
    end
    G.Parser:Initialize(_G); G.Client.killRegistered = true
    G.Storage:Initialize(G.Client:Context()); G.Trackers:Reset()
    return G
end
function H.start(G, id, name, duration)
    G.Storage.settings.duration = duration or 0
    assert(G.Session:Start({npcID = id or 259055, name = name or "Wildplains Huntress", zoneName = "Riverglades"}, G.Client:Context(), H.clock, time()))
    return G.Session.s
end
function H.at(t) H.clock = t; return t end
function H.kill(G, id, individual, name, source)
    local guid = H.guid(id or 259055, individual)
    G.Trackers:Credit(guid, name or "Wildplains Huntress", source or "Player-1-Tester", H.clock, "PARTY_KILL")
    return guid
end
function H.slot(G, guid, link, quantity)
    return {[1] = {kind = "item", itemLink = link, variantKey = G.ItemKey(link), quantity = quantity, sources = {{guid = guid, quantity = quantity}}}}
end
return H
