local _, G = ...
local M = {}; G.Minimap = M
function M:Position()
    local angle = math.rad(G.Storage.settings.minimapAngle or 215)
    local radius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 10
    local x, y = math.cos(angle), math.sin(angle)
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    -- Square/minimap replacement addons are allowed; keep the icon on the perimeter.
    if shape == "SQUARE" then
        local norm = math.max(math.abs(x), math.abs(y)); x = x / norm; y = y / norm
    end
    self.button:ClearAllPoints(); self.button:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end
function M:Update()
    self.button:SetShown(G.Storage.settings.showMinimap); self:Position()
end
function M:Create()
    local b = CreateFrame("Button", "GrindMeterMinimapButton", Minimap)
    self.button = b; b:SetSize(32, 32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
    local background = b:CreateTexture(nil, "BACKGROUND"); background:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); background:SetSize(25, 25); background:SetPoint("CENTER")
    local icon = b:CreateTexture(nil, "ARTWORK"); icon:SetTexture(G.icon); icon:SetSize(20, 20); icon:SetPoint("CENTER", -1, 1)
    local border = b:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(54, 54); border:SetPoint("TOPLEFT", 0, 0)
    b:SetScript("OnClick", function(_, mouse)
        if self.dragged then self.dragged = nil; return end
        if mouse == "RightButton" then G.UI.hud:SetShown(not G.UI.hud:IsShown()); G.UI:UpdateHUD()
        else G.UI:Toggle() end
    end)
    b:SetScript("OnEnter", function()
        GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText("GrindMeter", .88, .71, .4)
        local s = G.Session.s
        if s then GameTooltip:AddLine(s.selectedName .. " - " .. G.L(s.state == "running" and "running" or "paused"), 1, 1, 1) end
        GameTooltip:AddLine(G.L("miniHint"), .8, .85, .9, true); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart", function()
        self.dragged = true; GameTooltip:Hide()
        b:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition(); local scale = Minimap:GetEffectiveScale(); local cx, cy = Minimap:GetCenter()
            if not cx or not cy then return end
            G.Storage.settings.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx)); self:Position()
        end)
    end)
    b:SetScript("OnDragStop", function() b:SetScript("OnUpdate", nil) end)
    self:Update()
end
