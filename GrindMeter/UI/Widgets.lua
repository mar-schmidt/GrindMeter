local _, G = ...
local W = {}; G.W = W
W.colors = {bg = {.045, .055, .075, .98}, card = {.075, .09, .12, 1}, line = {.24, .27, .32, 1},
    text = {.91, .92, .94}, muted = {.62, .68, .75}, gold = {.88, .71, .40}, teal = {.36, .82, .72}, warning = {.98, .72, .34}}
function W.Panel(parent, width, height, color)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(width, height)
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(unpack(color or W.colors.card)); f:SetBackdropBorderColor(unpack(W.colors.line))
    return f
end
function W.Place(frame, x, y, parent)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", parent or frame:GetParent(), "TOPLEFT", x, -y)
    return frame
end
function W.Text(parent, text, size, color, width)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 13, "")
    f:SetTextColor(unpack(color or W.colors.text)); f:SetJustifyH("LEFT"); f:SetJustifyV("TOP")
    f:SetWordWrap(true); if width then f:SetWidth(width) end; f:SetText(text or "")
    return f
end
function W.Button(parent, text, width, height, action, primary)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 140, height or 32)
    button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    button.primary = primary
    button.label = W.Text(button, text, 12, primary and {.08, .08, .09} or W.colors.text)
    button.label:SetPoint("CENTER"); button.label:SetJustifyH("CENTER"); button.label:SetWidth((width or 140) - 12)
    button:SetFontString(button.label)
    function button:Paint(hover)
        if self.primary then self:SetBackdropColor(.88, .71, .40, hover and 1 or .94); self:SetBackdropBorderColor(.95, .8, .53, 1)
        elseif self.selected then self:SetBackdropColor(.19, .18, .14, 1); self:SetBackdropBorderColor(.72, .57, .31, 1)
        else self:SetBackdropColor(hover and .15 or .1, hover and .18 or .12, hover and .23 or .16, 1); self:SetBackdropBorderColor(unpack(W.colors.line)) end
    end
    function button:SetSelected(selected) self.selected = selected; self:Paint(false) end
    button:SetScript("OnEnter", function(self) self:Paint(true) end)
    button:SetScript("OnLeave", function(self) self:Paint(false) end)
    button:SetScript("OnClick", action); button:Paint(false)
    return button
end
function W.Enable(button, enabled)
    button:SetEnabled(enabled); button:SetAlpha(enabled and 1 or .4)
end
function W.Tooltip(frame, text)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(text, 1, 1, 1, 1, true); GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
function W.Draggable(frame, handle, key)
    frame:SetMovable(true); frame:SetClampedToScreen(true); handle:EnableMouse(true); handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() frame:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        G.Storage.settings[key] = {point = point, relativePoint = relativePoint, x = x, y = y}
    end)
end
function W.Position(frame, key, fallback, x, y)
    frame:ClearAllPoints()
    local p = G.Storage.settings[key]
    if type(p) == "table" and type(p.point) == "string" and type(p.x) == "number" and type(p.y) == "number" then
        frame:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x, p.y)
    else frame:SetPoint(fallback or "CENTER", UIParent, fallback or "CENTER", x or 0, y or 0) end
end
function W.Scroll(parent, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetSize(width, height)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(width - 8, height)
    scroll:SetScrollChild(content); scroll.content = content
    return scroll
end
function W.Edit(parent, width, height)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, height or 28); edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return edit
end
function W.Metric(parent, x, y, width)
    local card = W.Place(W.Panel(parent, width, 88), x, y)
    card.title = W.Place(W.Text(card, "", 11, W.colors.muted, width - 24), 12, 12)
    card.number = W.Place(W.Text(card, "—", 28, W.colors.text, width - 24), 12, 29)
    card.detail = W.Place(W.Text(card, "", 10, W.colors.muted, width - 24), 12, 65)
    return card
end
