local addonName, G = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
local loaded = false
local initialized, accumulated = false, 0
local function initialize()
    G.Parser:Initialize(_G)
    G.Client:Register(frame)
    G.Storage:Initialize(G.Client:Context())
    G.Trackers:Reset()
    G.Session:Restore(GetTime())
    G.UI:Create(); G.Minimap:Create()
    G.Session.OnStopped = function()
        G.Print(G.L("saved")); G.UI.view = nil; G.UI.newMode = nil; G.UI.revalued = nil
        if not InCombatLockdown() then G.UI:Refresh() else G.UI.dirty = true; G.UI:UpdateHUD() end
    end
    SLASH_GRINDMETER1 = "/grindmeter"; SLASH_GRINDMETER2 = "/gm"
    SlashCmdList.GRINDMETER = function(message)
        message = (message or ""):lower():match("^%s*(.-)%s*$")
        if message == "hud" then G.UI.hud:SetShown(not G.UI.hud:IsShown()); G.UI:UpdateHUD()
        elseif message == "diagnostics" or message == "diag" then G.UI:CopyBox(G.Client:Diagnostics())
        elseif message == "reset" then
            G.Storage.settings.windowPosition = nil; G.Storage.settings.hudPosition = nil
            G.Storage.settings.showMinimap = true; G.Storage.settings.minimapAngle = 215
            G.W.Position(G.UI.main, "windowPosition"); G.W.Position(G.UI.hud, "hudPosition", "TOPLEFT", 40, -210); G.Minimap:Update()
        elseif message == "help" then G.Print(G.L("help"))
        else G.UI:Toggle() end
    end
    if G.Session.s and G.Storage.settings.showHUD then G.UI.hud:Show(); G.Print(G.L("restored")) end
    initialized = true
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then
            loaded = true
            if not initialized and IsLoggedIn() then initialize() end
        end
        return
    end
    if event == "PLAYER_LOGIN" and loaded and not initialized then initialize(); return end
    if not initialized then return end
    local ok = pcall(G.Client.Dispatch, G.Client, event, ...)
    if not ok then
        -- No attempt to unwrap restricted values or recover forbidden payloads.
        G.Client.errors[event] = "payload-unavailable"
        if G.Session.s then
            G.Trackers:Diagnostic("unavailablePayload")
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then G.Session.s.killAvailable = false end
            if event == "CHAT_MSG_COMBAT_XP_GAIN" then G.Session.s.xpAvailable = false end
            if event:match("^LOOT_") or event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_MONEY" then G.Session.s.lootUnavailable = true end
        end
        G.UI.dirty = true
    end
end)
frame:SetScript("OnUpdate", function(_, elapsed)
    accumulated = accumulated + elapsed
    if not initialized or accumulated < .25 then return end
    accumulated = 0
    local now = GetTime()
    G.Session:Tick(now); G.Trackers:FlushXP(now)
    if G.UI.hud:IsShown() then G.UI:UpdateHUD() end
    if G.UI.main:IsShown() and (G.UI.dirty or G.Session.s) then
        if G.UI.tab == "measure" and G.UI.result:IsShown() and not G.UI.dirty then G.UI:UpdateResult()
        else G.UI:Refresh() end
    end
end)
G.eventFrame = frame
