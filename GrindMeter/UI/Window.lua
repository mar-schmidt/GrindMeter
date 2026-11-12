local _, G = ...
local U = {tab = "measure", lootTab = "observed", sort = "quality", dirty = true}; G.UI = U
local W, F = G.W, G.F
local function label(parent, key, x, y, size, color, width)
    return W.Place(W.Text(parent, G.L(key), size, color, width), x, y)
end
local function button(parent, key, x, y, width, action, primary, height)
    return W.Place(W.Button(parent, G.L(key), width, height or 32, action, primary), x, y)
end
function U:ActiveView()
    return self.view or G.Session.s or G.Session.last
end
function U:ChooseTarget()
    if G.Session.s then G.Print(G.L("alreadyRunning")); return end
    local selection = G.Client:Selection()
    if not selection then self.setupError = G.L("noTarget")
    else self.selection = selection; self.setupError = nil; self.view = nil; self.newMode = true end
    self:Refresh()
end
function U:Start()
    local context = G.Client:Context()
    if context.gameFlavor ~= "forever" then self.setupError = "WoW Forever (Interface 16000–16999)"; self:Refresh(); return end
    local ok, reason = G.Session:Start(self.selection, context, GetTime(), time())
    if not ok then self.setupError = G.L(reason); self:Refresh(); return end
    G.Trackers:XPDelta(UnitXP("player"), UnitXPMax("player"), UnitLevel("player"), GetTime())
    self.view = nil; self.revalued = nil; self.newMode = nil; self.setupError = nil
    self:Refresh()
    if G.Storage.settings.showHUD then self.hud:Show() end
end
function U:Create()
    self.main = W.Panel(UIParent, 860, 710, W.colors.bg)
    local frame = self.main; frame:SetFrameStrata("DIALOG")
    frame:SetScale(math.min(1, (UIParent:GetWidth() - 36) / 860, (UIParent:GetHeight() - 48) / 710))
    W.Position(frame, "windowPosition")
    local handle = CreateFrame("Frame", nil, frame); handle:SetPoint("TOPLEFT"); handle:SetSize(810, 65)
    W.Draggable(frame, handle, "windowPosition")
    local icon = frame:CreateTexture(nil, "ARTWORK"); icon:SetTexture(G.icon); icon:SetSize(30, 30); W.Place(icon, 22, 23)
    W.Place(W.Text(frame, "GrindMeter", 21, W.colors.gold), 64, 18)
    self.subtitle = label(frame, "subtitle", 65, 43, 11, W.colors.muted)
    self.close = W.Place(W.Button(frame, "×", 30, 30, function() frame:Hide() end), 809, 20)
    self.nav = {}
    for i, key in ipairs({"measure", "history", "settings"}) do
        self.nav[key] = button(frame, key, 20 + (i - 1) * 171, 76, 161, function()
            self.tab = key; self.deleteArmed = nil; self:Refresh()
        end)
    end
    self.setup = CreateFrame("Frame", nil, frame); self.setup:SetAllPoints()
    self.result = CreateFrame("Frame", nil, frame); self.result:SetAllPoints()
    self.history = CreateFrame("Frame", nil, frame); self.history:SetAllPoints()
    self.settings = CreateFrame("Frame", nil, frame); self.settings:SetAllPoints()
    self:CreateSetup(); self:CreateResult(); self:CreateHistory(); self:CreateSettings(); self:CreateHUD()
    self.footer = W.Place(W.Text(frame, "", 9, W.colors.muted, 818), 22, 676)
    frame:Hide()
end
function U:CreateSetup()
    local p = self.setup
    local mob = W.Place(W.Panel(p, 820, 157), 20, 125)
    self.targetHeading = label(mob, "step1", 18, 16, 11, W.colors.gold)
    self.targetName = label(mob, "choose", 18, 45, 22, W.colors.text, 500)
    self.targetMeta = W.Place(W.Text(mob, "", 12, W.colors.muted, 490), 18, 80)
    self.targetHint = label(mob, "selectHint", 18, 120, 12, W.colors.muted, 780)
    self.targetButton = button(mob, "select", 562, 44, 238, function() self:ChooseTarget() end)
    local duration = W.Place(W.Panel(p, 820, 118), 20, 299)
    self.durationHeading = label(duration, "step2", 18, 16, 11, W.colors.gold)
    self.durations = {}
    for i, seconds in ipairs({300, 600, 900, 1800, 0}) do
        local text = seconds == 0 and G.L("manual") or seconds / 60 .. " " .. G.L("min")
        self.durations[seconds] = W.Place(W.Button(duration, text, i == 5 and 218 or 130, 32, function()
            G.Storage.settings.duration = seconds; self:Refresh()
        end), 18 + (i - 1) * 143, 43)
    end
    self.timeHint = label(duration, "timeHint", 18, 91, 11, W.colors.muted, 790)
    local start = W.Place(W.Panel(p, 820, 148), 20, 434)
    self.startHeading = label(start, "step3", 18, 16, 11, W.colors.gold)
    self.startHint = label(start, "startHint", 18, 47, 14, W.colors.text, 500)
    self.startButton = button(start, "start", 562, 48, 238, function() self:Start() end, true, 48)
    self.setupNotice = W.Place(W.Text(p, "", 12, W.colors.warning, 815), 22, 601)
    self.setupHelp = label(p, "ahHelp", 22, 639, 11, W.colors.muted, 815)
end
function U:CreateResult()
    local p = self.result
    self.mobName = W.Place(W.Text(p, "", 22, W.colors.text, 590), 22, 125)
    self.status = W.Place(W.Text(p, "", 11, W.colors.teal, 220), 618, 131); self.status:SetJustifyH("RIGHT")
    self.meta = W.Place(W.Text(p, "", 11, W.colors.muted, 815), 22, 156)
    self.timing = W.Place(W.Text(p, "", 12, W.colors.text, 815), 22, 180)
    self.progress = W.Place(W.Panel(p, 816, 4, {.16, .19, .24, 1}), 22, 202)
    self.progressFill = self.progress:CreateTexture(nil, "ARTWORK"); self.progressFill:SetColorTexture(unpack(W.colors.gold));
    self.progressFill:SetPoint("TOPLEFT"); self.progressFill:SetHeight(4)
    self.cards = {W.Metric(p, 20, 219, 266), W.Metric(p, 297, 219, 266), W.Metric(p, 574, 219, 266)}
    self.totals = W.Place(W.Text(p, "", 10, W.colors.muted, 815), 22, 314)
    self.qualityBox = W.Place(W.Panel(p, 820, 52), 20, 359)
    self.qualityLabel = W.Place(W.Text(self.qualityBox, "", 11, W.colors.warning, 790), 12, 10)
    self.lootTabs = {}
    for i, key in ipairs({"observed", "possible", "other"}) do
        self.lootTabs[key] = button(p, key, 20 + (i - 1) * 151, 424, 143, function()
            self.lootTab = key; self:UpdateLoot()
        end)
    end
    self.sortButton = W.Place(W.Button(p, "", 180, 32, function()
        local nextSort = {quality = "name", name = "drop", drop = "value", value = "quality"}
        self.sort = nextSort[self.sort]; self:UpdateLoot()
    end), 660, 424)
    self.lootScroll = W.Place(W.Scroll(p, 792, 137), 22, 467)
    self.lootRows = {}; self.lootEmpty = W.Place(W.Text(self.lootScroll.content, "", 13, W.colors.muted, 760), 6, 12)
    self.pauseButton = button(p, "pause", 20, 628, 140, function()
        if not G.Session.s then return end
        if G.Session.s.state == "running" then G.Session:Pause(GetTime()) else G.Session:Resume(GetTime()) end
        self:Refresh()
    end)
    self.stopButton = button(p, "stop", 172, 628, 207, function() G.Session:Stop(GetTime(), time(), "manual"); self.view = nil; self:Refresh() end, true)
    self.newButton = button(p, "new", 20, 628, 219, function()
        local s = self:ActiveView(); self.selection = {npcID = s.selectedNpcID, name = s.selectedName, zoneName = s.zoneName, mapID = s.mapID}
        self.view = nil; self.newMode = true; self.revalued = nil; self:Refresh()
    end, true)
    self.otherButton = button(p, "otherTarget", 251, 628, 165, function()
        self.view = nil; self.selection = nil; self.newMode = true; self.revalued = nil; self:Refresh()
    end)
    self.exportButton = button(p, "export", 583, 628, 257, function() self:CopyBox(self:Summary(self:ActiveView())) end)
    self.revalueButton = button(p, "revalueShort", 428, 628, 145, function()
        self.revalued = G.Prices:Snapshot(self:ActiveView()); self:Refresh()
    end)
    W.Tooltip(self.revalueButton, G.L("revalue"))
    self.methodSwitch = W.Place(W.Button(p, "", 190, 32, function()
        G.Storage.settings.method = G.Storage.settings.method == "vendor" and "best" or "vendor"; self:Refresh()
    end), 391, 628)
    self.cards[3]:EnableMouse(true)
    self.cards[3]:SetScript("OnMouseDown", function()
        G.Storage.settings.method = G.Storage.settings.method == "vendor" and "best" or "vendor"; self:Refresh()
    end)
end
function U:CreateHistory()
    local p = self.history
    self.historyHeading = label(p, "history", 22, 130, 23, W.colors.text)
    self.historyHint = label(p, "historyHint", 22, 167, 12, W.colors.muted, 810)
    self.filterLabel = label(p, "filter", 22, 211, 11, W.colors.muted)
    self.filter = W.Place(W.Edit(p, 450, 30), 28, 234)
    self.filter:SetScript("OnTextChanged", function() if G.Storage.character then self:UpdateHistory() end end)
    self.historyScroll = W.Place(W.Scroll(p, 790, 305), 22, 283)
    self.historyRows = {}; self.historyEmpty = W.Place(W.Text(self.historyScroll.content, "", 13, W.colors.muted, 760), 6, 12)
    self.historyDelete = button(p, "delete", 22, 625, 250, function()
        if not self.historySelected then return end
        if self.deleteArmed == self.historySelected.id then
            G.Storage:Delete(self.historySelected.id)
            if self.view == self.historySelected then self.view = nil end
            self.historySelected = nil; self.deleteArmed = nil; self:Refresh()
        else self.deleteArmed = self.historySelected.id; self.historyDelete:SetText(G.L("deleteConfirm")) end
    end)
    self.historyDetail = W.Place(W.Button(p, "", 540, 32, function()
        if self.historySelected then self.view = self.historySelected; self.revalued = nil; self.newMode = nil; self.tab = "measure"; self:Refresh() end
    end), 299, 625)
end
function U:CreateSettings()
    local p = self.settings
    self.settingsHeading = label(p, "settings", 22, 130, 23, W.colors.text)
    self.languageLabel = label(p, "language", 22, 185, 13)
    self.sv = W.Place(W.Button(p, "Svenska", 140, 32, function() G.Storage.settings.language = "sv"; self:Refresh() end), 480, 177)
    self.en = W.Place(W.Button(p, "English", 140, 32, function() G.Storage.settings.language = "en"; self:Refresh() end), 640, 177)
    self.minimapToggle = button(p, "minimap", 22, 235, 758, function()
        G.Storage.settings.showMinimap = not G.Storage.settings.showMinimap; G.Minimap:Update(); self:Refresh()
    end)
    self.hudToggle = button(p, "hud", 22, 282, 758, function()
        G.Storage.settings.showHUD = not G.Storage.settings.showHUD
        if not G.Storage.settings.showHUD then self.hud:Hide() elseif G.Session.s then self.hud:Show() end
        self:Refresh()
    end)
    self.methodButton = W.Place(W.Button(p, "", 758, 32, function()
        local settings = G.Storage.settings; settings.method = settings.method == "vendor" and "best" or "vendor"; self:Refresh()
    end), 22, 329)
    self.feeLabel = label(p, "fee", 22, 389, 13)
    self.feeEdit = W.Place(W.Edit(p, 90, 28), 242, 381); self.feeEdit:SetNumeric(true)
    self.feeEdit:SetScript("OnEnterPressed", function(edit)
        local value = tonumber(edit:GetText()); if value and value >= 0 and value <= 50 then G.Storage.settings.fee = value / 100 end
        edit:ClearFocus(); self:Refresh()
    end)
    self.feeHint = label(p, "feeHint", 350, 389, 11, W.colors.muted, 450)
    self.ageLabel = label(p, "age", 22, 436, 12)
    self.ageEdit = W.Place(W.Edit(p, 90, 28), 350, 428); self.ageEdit:SetNumeric(true)
    self.ageEdit:SetScript("OnEnterPressed", function(edit)
        local value = tonumber(edit:GetText()); if value and value >= 1 and value <= 720 then G.Storage.settings.staleHours = value end
        edit:ClearFocus(); self:Refresh()
    end)
    self.hoursLabel = label(p, "hours", 462, 436, 12, W.colors.muted)
    self.ahHelp = label(p, "ahHelp", 22, 487, 12, W.colors.muted, 780)
    self.diagnostic = button(p, "diagnose", 22, 561, 300, function() self:CopyBox(G.Client:Diagnostics()) end)
    self.diagnosticHint = label(p, "diagnosticHint", 22, 610, 11, W.colors.muted, 780)
end
function U:CreateHUD()
    self.hud = W.Panel(UIParent, 308, 190, W.colors.bg)
    local h = self.hud; h:SetFrameStrata("MEDIUM"); W.Position(h, "hudPosition", "TOPLEFT", 40, -210)
    local handle = CreateFrame("Frame", nil, h); handle:SetSize(270, 31); handle:SetPoint("TOPLEFT")
    W.Draggable(h, handle, "hudPosition")
    W.Place(W.Text(h, "GrindMeter", 12, W.colors.gold), 12, 12)
    self.hudClose = W.Place(W.Button(h, "×", 24, 24, function() h:Hide() end), 277, 5)
    W.Tooltip(self.hudClose, G.L("minimize"))
    self.hudMob = W.Place(W.Text(h, "", 15, W.colors.text, 282), 12, 40)
    self.hudTime = W.Place(W.Text(h, "", 11, W.colors.muted, 282), 12, 65)
    self.hudNumbers = W.Place(W.Text(h, "", 13, W.colors.text, 282), 12, 89)
    self.hudMethod = W.Place(W.Text(h, "", 10, W.colors.muted, 282), 12, 122)
    self.hudPause = button(h, "pause", 12, 148, 126, function()
        if not G.Session.s then self.tab = "measure"; self.view = nil; self.newMode = nil; self:Refresh(); self.main:Show(); return end
        if G.Session.s.state == "running" then G.Session:Pause(GetTime()) else G.Session:Resume(GetTime()) end
        self:Refresh()
    end)
    self.hudStop = button(h, "stop", 149, 148, 147, function()
        if G.Session.s then G.Session:Stop(GetTime(), time(), "manual")
        else self.tab = "history"; self.main:Show() end
        self:Refresh()
    end)
    h:Hide()
end
function U:Refresh()
    if not self.main then return end
    for _, key in ipairs({"measure", "history", "settings"}) do self.nav[key]:SetText(G.L(key)); self.nav[key]:SetSelected(self.tab == key) end
    self.subtitle:SetText(G.L("subtitle"))
    self.setup:Hide(); self.result:Hide(); self.history:Hide(); self.settings:Hide()
    self.footer:SetText(G.L("beforeCosts") .. "\n" .. G.L("diagnosticsWarning") .. "  ·  " .. G.L("extrapolated"))
    if self.tab == "history" then self.history:Show(); self:UpdateHistory()
    elseif self.tab == "settings" then self.settings:Show(); self:UpdateSettings()
    elseif self:ActiveView() and (not self.newMode or G.Session.s) then self.result:Show(); self:UpdateResult(); self:UpdateLoot()
    else self.setup:Show(); self:UpdateSetup() end
    self:UpdateHUD(); self.dirty = false
end
function U:UpdateSetup()
    local selection = self.selection
    self.targetHeading:SetText(G.L("step1"))
    self.targetName:SetText(selection and selection.name or G.L("choose"))
    self.targetMeta:SetText(selection and "NPC " .. selection.npcID .. "  ·  " .. (selection.zoneName or "") or "")
    self.targetHint:SetText(self.setupError or G.L(selection and "selectedHint" or "selectHint"))
    self.targetButton:SetText(G.L("select")); self.startButton:SetText(G.L("start")); W.Enable(self.startButton, selection ~= nil)
    self.durationHeading:SetText(G.L("step2")); self.timeHint:SetText(G.L("timeHint")); self.startHeading:SetText(G.L("step3"))
    self.startHint:SetText(G.L("startHint")); self.setupHelp:SetText(G.L("ahHelp"))
    for seconds, b in pairs(self.durations) do
        b:SetText(seconds == 0 and G.L("manual") or seconds / 60 .. " " .. G.L("min")); b:SetSelected(G.Storage.settings.duration == seconds)
    end
    local entries = selection and G.Catalog:Get(selection.npcID) or {}
    self.setupNotice:SetText(self.setupError or (selection and (#entries > 0 and G.L("catalogCount", #entries) or G.L("missingCatalog")) or G.L("selectHint")))
end
function U:UpdateResult()
    local s = self:ActiveView(); if not s then return end
    G.Prices:FillItemData(s)
    local method = G.Storage.settings.method
    local m = G.Calculator.Metrics(s, s.selectedNpcID, method, self.revalued)
    local total = G.Calculator.Metrics(s, nil, method, self.revalued)
    self.mobName:SetText(s.selectedName)
    self.status:SetText(G.L(s.state == "running" and "running" or s.state == "paused" and "paused" or "finished"))
    self.meta:SetText("NPC " .. s.selectedNpcID .. "  ·  " .. (s.zoneName or "") .. "  ·  " .. F.Date(s.startedAt)
        .. "  ·  Lv " .. s.levelStart .. (s.levelEnd and s.levelEnd ~= s.levelStart and " → " .. s.levelEnd or "")
        .. "  ·  " .. G.L(s.groupInfo == "solo" and "solo" or "group") .. (s.groupChanged and " · " .. G.L("groupChanged") or ""))
    local timing = G.L("measured") .. " " .. F.Time(s.measuredSeconds)
    if s.duration > 0 then timing = timing .. "  ·  " .. G.L("remaining") .. " " .. F.Time(math.max(0, s.duration - s.measuredSeconds)) end
    if s.pausedSeconds > 0 then timing = timing .. "  ·  " .. G.L("pausedTime") .. " " .. F.Time(s.pausedSeconds) end
    self.timing:SetText(timing); self.progressFill:SetWidth(math.max(1, s.duration > 0 and 816 * math.min(1, s.measuredSeconds / s.duration) or 816))
    local c = self.cards
    c[1].title:SetText(G.L("selectedMob") .. " · " .. G.L("killsHour")); c[1].number:SetText(F.Number(m.killsHour))
    c[1].detail:SetText(m.kills .. " " .. G.L("kills") .. " · " .. F.Number(m.secondsKill) .. " s/kill")
    c[2].title:SetText(G.L("xpHour") .. (m.xpPartial and " · " .. G.L("partial") or "")); c[2].number:SetText(F.Number(m.xpHour))
    c[2].detail:SetText((s.xpAvailable and m.xp or G.L("unknown")) .. " " .. G.L("totalXP") .. " · " .. G.L("restedStart") .. " " .. tostring(s.restedInfo or 0))
    c[3].title:SetText(G.L("valueHour") .. (m.valuation.partial and " · " .. G.L("partial") or "")); c[3].number:SetText(F.Gold(m.valuation.rate))
    c[3].detail:SetText(G.L(method) .. (self.revalued and " · " .. G.L("revaluedShort") or ""))
    local vendor = G.Calculator.Value(s, s.selectedNpcID, "vendor", self.revalued)
    local best = G.Calculator.Value(s, s.selectedNpcID, "best", self.revalued)
    self.totals:SetText(G.L("wholeSession") .. ((total.xpPartial or total.valuation.partial) and " (" .. G.L("partial") .. ")" or "") .. ":  " .. total.kills .. " kills  ·  " .. F.Number(total.killsHour) .. " kills/h  ·  "
        .. F.Number(total.xpHour) .. " XP/h  ·  " .. F.Gold(total.valuation.rate) .. " G/h\n"
        .. G.L("selectedMob") .. ": " .. G.L("coins") .. " " .. F.Money(m.valuation.coins)
        .. " · " .. G.L("vendor") .. " " .. F.Gold(vendor.rate) .. " G/h · " .. G.L("best") .. " " .. F.Gold(best.rate) .. " G/h"
        .. ((vendor.partial or best.partial) and " · " .. G.L("partial") or "")
        .. (s.unattributedMoney > 0 and "\n" .. G.L("unknownCoins") .. ": " .. F.Money(s.unattributedMoney) or ""))
    local note = G.L("diagnosticsLine", s.unattributedXP, s.unattributedLoot, m.valuation.unknown, m.valuation.stale)
        .. (method ~= "vendor" and " · " .. G.L("ahMissingCount", m.valuation.ahMissing) or "")
    if not s.killAvailable then note = G.L("combatRestricted")
    elseif not s.xpAvailable then note = G.L("xpUnavailable")
    elseif s.recovered and s.state == "paused" then note = G.L("restored")
    elseif not s.diagnosticsSummary.confirmedKills then note = G.L("awaitingCredit") end
    self.qualityLabel:SetText(note .. "\n" .. (self.revalued and G.L("revalued") or m.preliminary and G.L("preliminary") or G.L("rested")))
    local active = G.Session.s == s
    self.pauseButton:SetShown(active); self.stopButton:SetShown(active); self.newButton:SetShown(not active); self.otherButton:SetShown(not active)
    W.Enable(self.newButton, not G.Session.s); W.Enable(self.otherButton, not G.Session.s)
    self.pauseButton:SetText(G.L(s.state == "paused" and "resume" or "pause")); self.stopButton:SetText(G.L("stop"))
    self.newButton:SetText(G.L("new")); self.otherButton:SetText(G.L("otherTarget")); self.exportButton:SetText(G.L("export"))
    self.revalueButton:SetShown(not active); self.revalueButton:SetText(G.L("revalueShort"))
    self.methodSwitch:SetShown(active); self.methodSwitch:SetText(G.L(G.Storage.settings.method))
end
function U:Rows(session)
    local rows = {}
    if self.lootTab == "possible" then return G.Catalog:Get(session.selectedNpcID) end
    if self.lootTab == "other" then
        for id, counter in pairs(session.countersByNpcID) do
            if id ~= session.selectedNpcID then
                local metrics = G.Calculator.Metrics(session, id, G.Storage.settings.method, self.revalued)
                rows[#rows + 1] = {npcID = id, name = counter.name, metrics = metrics}
            end
        end
        return rows
    end
    local grouped = {}
    for _, receipt in ipairs(session.lootReceipts) do
        local key = receipt.variantKey .. ":" .. (receipt.sourceNpcID or "unknown")
        local row = grouped[key]
        if not row then row = G.Copy(receipt); row.quantity = 0; grouped[key] = row; rows[#rows + 1] = row end
        row.quantity = row.quantity + receipt.quantity
    end
    return rows
end
function U:LootRow(index)
    if self.lootRows[index] then return self.lootRows[index] end
    local parent = self.lootScroll.content
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate"); row:SetSize(775, 51)
    row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.09, .105, .135, .7)
    row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(31, 31); W.Place(row.icon, 6, 9)
    row.title = W.Place(W.Text(row, "", 12, W.colors.text, 448), 47, 8)
    row.sub = W.Place(W.Text(row, "", 10, W.colors.muted, 595), 47, 29)
    row.value = W.Place(W.Text(row, "", 11, W.colors.gold, 155), 532, 8); row.value:SetJustifyH("RIGHT")
    row.link = W.Place(W.Button(row, G.L("link"), 65, 26, function()
        if row.data and row.data.itemLink then
            if not ChatEdit_InsertLink(row.data.itemLink) then ChatFrame_OpenChat(row.data.itemLink) end
        end
    end), 703, 11)
    row:SetScript("OnClick", function()
        local link = row.data and row.data.itemLink
        if link then
            if IsModifiedClick and IsModifiedClick("CHATLINK") then
                if not ChatEdit_InsertLink(link) then ChatFrame_OpenChat(link) end
            elseif HandleModifiedItemClick and HandleModifiedItemClick(link) then return
            elseif ItemRefTooltip then SetItemRef(G.ItemKey(link), link, "LeftButton") end
        end
    end)
    row:SetScript("OnEnter", function()
        if not row.data or not row.data.itemLink then return end
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(row.data.itemLink)
        local price = row.price or {}
        GameTooltip:AddLine(" "); GameTooltip:AddLine(G.L("vendorUnit") .. ": " .. F.Money(price.vendor), 1, 1, 1)
        if price.ah then
            local ah = price.ah
            GameTooltip:AddLine(G.L("ahUnit") .. ": " .. F.Money(ah.unitPriceCopper) .. " · minimumBuyout", 1, 1, 1)
            GameTooltip:AddLine(ah.sourceName .. " " .. (ah.sourceVersion or "") .. " · " .. ah.scope.region .. " / " .. ah.scope.realm .. " / " .. ah.scope.faction, .7, .75, .8, true)
            GameTooltip:AddLine(ah.ageDays and G.L("dayAge", ah.ageDays * 24, (ah.ageDays + 1) * 24) or F.Date(ah.observedAt), .9, .75, .4, true)
            if ah.stale then GameTooltip:AddLine(G.L("stale"), 1, .6, .2) end
        else GameTooltip:AddLine(G.L("ahMissing"), .9, .7, .4) end
        if price.tradeEligible == false then GameTooltip:AddLine(G.L("notTradable"), .8, .7, .6) end
        if row.data.variantPolicy == "base-only" then GameTooltip:AddLine(G.L("baseVariant"), .8, .7, .6, true) end
        GameTooltip:AddLine(G.L("linkHint"), .6, .7, .8, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.lootRows[index] = row; return row
end
function U:UpdateLoot()
    local s = self:ActiveView(); if not s then return end
    for key, b in pairs(self.lootTabs) do b:SetText(G.L(key)); b:SetSelected(key == self.lootTab) end
    self.sortButton:SetText(G.L("sort") .. ": " .. (self.sort == "quality" and "★" or G.L(self.sort)))
    local rows, coverage = self:Rows(s)
    local prices = self.revalued or s.priceSnapshot
    for _, row in ipairs(rows) do
        if row.itemID then
            row.price = prices[row.variantKey] or G.Prices:Resolve(row.itemLink or "item:" .. row.itemID, s, time())
            row.itemLink = row.itemLink or row.price.link
            row.displayName = row.price.name or G.L("itemLoading", row.itemID)
        end
    end
    table.sort(rows, function(a, b)
        if a.npcID then return a.metrics.kills > b.metrics.kills end
        if self.sort == "name" then return a.displayName < b.displayName end
        if self.sort == "drop" then
            local pa, pb = a.probability or (a.bodies and a.bodies > 0 and a.hits / a.bodies) or -1, b.probability or (b.bodies and b.bodies > 0 and b.hits / b.bodies) or -1
            if pa ~= pb then return pa > pb end
        elseif self.sort == "quality" then
            local qa, qb = a.price.quality or -1, b.price.quality or -1
            if qa ~= qb then return qa > qb end
        end
        local va = G.Calculator.ItemValue(a.price, G.Storage.settings.method, s.fee) or -1
        local vb = G.Calculator.ItemValue(b.price, G.Storage.settings.method, s.fee) or -1
        return va == vb and a.displayName < b.displayName or va > vb
    end)
    for _, row in ipairs(self.lootRows) do row:Hide() end
    local offset = self.lootTab == "possible" and 72 or 0
    self.lootEmpty:SetShown(#rows == 0 or self.lootTab == "possible")
    local emptyKey = self.lootTab == "possible" and (#rows > 0 and "catalogPartial" or "missingCatalog") or self.lootTab == "other" and "noOther" or "emptyLoot"
    self.lootEmpty:SetText(G.L(emptyKey))
    if self.lootTab == "possible" and #rows > 0 then
        local hasCommunity = false
        for _, row in ipairs(rows) do if row.source == "Everloot" then hasCommunity = true; break end end
        local forecast = G.Calculator.Forecast(rows, G.Calculator.Metrics(s, s.selectedNpcID, G.Storage.settings.method).killsHour,
            function(item) return G.Calculator.ItemValue(item.price, G.Storage.settings.method, s.fee) end, s.fee)
        local forecastText = forecast.value and G.L("forecast") .. ": " .. F.Gold(forecast.value) .. (forecast.partial and " · " .. G.L("partialForecast") or "") or G.L("forecastMissing")
        self.lootEmpty:SetText(G.L("catalogPartial") .. "\n" .. (hasCommunity and G.L("catalogCredit", G.Catalog.community.dataAsOf:sub(1, 10)) or G.L("localBias")) .. "\n" .. forecastText)
    end
    if self.lootTab == "possible" and #rows == 0 then self.lootEmpty:SetText(G.L("missingCatalog") .. "\n\n" .. G.L("forecastMissing")) end
    for i, data in ipairs(rows) do
        local row = self:LootRow(i); W.Place(row, 0, offset + (i - 1) * 57); row:Show(); row.data = data; row.price = data.price
        row.link:SetShown(data.itemID ~= nil); row.link:SetText(G.L("link"))
        if data.npcID then
            row.icon:SetTexture(nil); row.title:SetText(data.name .. " · NPC " .. data.npcID)
            row.value:SetText(data.metrics.kills .. " kills")
            row.sub:SetText(F.Number(data.metrics.killsHour) .. " kills/h · " .. F.Number(data.metrics.xpHour) .. " XP/h · " .. F.Gold(data.metrics.valuation.rate) .. " G/h")
        else
            local price = data.price; local unit, recommendation = G.Calculator.ItemValue(price, G.Storage.settings.method, s.fee)
            row.icon:SetTexture(price.icon)
            local quality = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[price.quality or 1]
            row.title:SetText(data.itemLink or price.link or data.displayName)
            if quality then row.title:SetTextColor(quality.r, quality.g, quality.b) else row.title:SetTextColor(unpack(W.colors.text)) end
            row.value:SetText(self.lootTab == "possible" and (data.probability and string.format("%.2f%%", data.probability * 100) or "—") or "×" .. data.quantity .. " · " .. F.Money(unit and unit * data.quantity))
            local source = data.sourceNpcID and (s.countersByNpcID[data.sourceNpcID] or {}).name or G.L("unknownSource")
            local detail = G.L("vendorUnit") .. " " .. F.Money(price.vendor) .. "  ·  " .. G.L("ahUnit") .. " " .. F.Money(price.ah and price.ah.unitPriceCopper)
            if self.lootTab == "possible" then
                detail = data.bodies and G.L("observedDrop", data.hits, data.bodies, data.units / math.max(1, data.bodies))
                    or data.windowCount and G.L("communitySample", data.probability * 100, data.windowCount, data.reporters) or G.L("forecastMissing")
            else detail = detail .. "  ·  " .. source .. "  ·  " .. recommendation end
            row.sub:SetText(detail)
        end
    end
    self.lootScroll.content:SetHeight(math.max(137, offset + #rows * 57))
end
function U:UpdateHistory()
    self.historyHeading:SetText(G.L("history")); self.historyHint:SetText(G.L("historyHint")); self.filterLabel:SetText(G.L("filter"))
    self.historyDelete:SetText(G.L("delete")); self.historyDetail:SetText(G.L("viewResult") .. " →")
    W.Enable(self.historyDelete, self.historySelected ~= nil); W.Enable(self.historyDetail, self.historySelected ~= nil)
    local filter = self.filter:GetText():lower(); local rows = {}
    for _, s in ipairs(G.Storage.character.history) do
        if filter == "" or s.selectedName:lower():find(filter, 1, true) or tostring(s.selectedNpcID):find(filter, 1, true) then rows[#rows + 1] = s end
    end
    for _, row in ipairs(self.historyRows) do row:Hide() end
    self.historyEmpty:SetText(G.L("noHistory")); self.historyEmpty:SetShown(#rows == 0)
    for i, s in ipairs(rows) do
        local row = self.historyRows[i]
        if not row then
            row = W.Button(self.historyScroll.content, "", 769, 68, function(b)
                self.historySelected = b.session; self.deleteArmed = nil; self:UpdateHistory()
            end)
            row.label:Hide(); row.title = W.Place(W.Text(row, "", 14, W.colors.text, 735), 12, 10)
            row.detail = W.Place(W.Text(row, "", 11, W.colors.muted, 735), 12, 37)
            self.historyRows[i] = row
        end
        row.session = s; W.Place(row, 0, (i - 1) * 76); row:Show(); row:SetSelected(self.historySelected == s)
        local m = G.Calculator.Metrics(s, s.selectedNpcID, G.Storage.settings.method)
        local priceDate
        for _, p in pairs(s.priceSnapshot) do if p.ah and (not priceDate or p.ah.observedAt < priceDate) then priceDate = p.ah.observedAt end end
        row.title:SetText(s.selectedName .. "  ·  " .. F.Time(s.measuredSeconds) .. "  ·  " .. F.Number(m.killsHour) .. " kills/h  ·  " .. F.Number(m.xpHour) .. " XP/h  ·  " .. F.Gold(m.valuation.rate) .. " G/h")
        row.detail:SetText(F.Date(s.startedAt) .. " · Lv " .. s.levelStart .. " · " .. G.L("restedStart") .. " " .. (s.restedInfo or 0)
            .. " · " .. G.L(s.groupInfo == "solo" and "solo" or "group") .. " · AH " .. (priceDate and F.Date(priceDate) or "—") .. ((m.valuation.partial or m.xpPartial) and " · " .. G.L("partial") or ""))
    end
    self.historyScroll.content:SetHeight(math.max(305, #rows * 76))
end
function U:UpdateSettings()
    self.settingsHeading:SetText(G.L("settings")); self.languageLabel:SetText(G.L("language"))
    self.sv:SetSelected(G.Storage.settings.language == "sv"); self.en:SetSelected(G.Storage.settings.language == "en")
    for _, row in ipairs({{self.minimapToggle, "minimap", "showMinimap"}, {self.hudToggle, "hud", "showHUD"}}) do
        row[1]:SetText((G.Storage.settings[row[3]] and "✓  " or "○  ") .. G.L(row[2]))
    end
    self.methodButton:SetText(G.L("value") .. ": " .. G.L(G.Storage.settings.method))
    self.feeLabel:SetText(G.L("fee") .. " (%)"); self.feeEdit:SetText(tostring(math.floor(G.Storage.settings.fee * 100 + .5)))
    self.feeHint:SetText(G.L("feeHint")); self.ageLabel:SetText(G.L("age")); self.ageEdit:SetText(tostring(G.Storage.settings.staleHours))
    self.hoursLabel:SetText(G.L("hours")); self.ahHelp:SetText(G.L("ahHelp")); self.diagnostic:SetText(G.L("diagnose")); self.diagnosticHint:SetText(G.L("diagnosticHint"))
end
function U:UpdateHUD()
    local s = G.Session.s or G.Session.last
    if not s then return end
    local m = G.Calculator.Metrics(s, s.selectedNpcID, G.Storage.settings.method)
    self.hudMob:SetText(s.selectedName)
    self.hudTime:SetText(G.L(s.state == "running" and "running" or s.state == "paused" and "paused" or "finished") .. " · " .. F.Time(s.measuredSeconds)
        .. (s.duration > 0 and " / " .. F.Time(s.duration) or ""))
    self.hudNumbers:SetText(F.Number(m.killsHour) .. " kills/h   ·   " .. F.Number(m.xpHour) .. " XP/h\n" .. F.Gold(m.valuation.rate) .. " G/h · " .. G.L("value"))
    self.hudMethod:SetText(G.L(G.Storage.settings.method) .. ((m.valuation.partial or m.xpPartial) and " · " .. G.L("partial") or ""))
    self.hudPause:SetText(G.L(s.state == "paused" and "resume" or s.state == "running" and "pause" or "measure"))
    self.hudStop:SetText(G.L(s.state == "finished" and "history" or "stop"))
end
function U:CopyBox(text)
    if not self.copy then
        self.copy = W.Panel(UIParent, 690, 380, W.colors.bg); self.copy:SetPoint("CENTER"); self.copy:SetFrameStrata("FULLSCREEN_DIALOG")
        local title = label(self.copy, "copyHint", 20, 20, 12, W.colors.muted, 620)
        W.Place(W.Button(self.copy, "×", 26, 26, function() self.copy:Hide() end), 652, 10)
        local scroll = W.Place(W.Scroll(self.copy, 620, 285), 22, 64)
        self.copyEdit = CreateFrame("EditBox", nil, scroll.content); self.copyEdit:SetMultiLine(true); self.copyEdit:SetAutoFocus(false)
        self.copyEdit:SetFontObject(ChatFontNormal); self.copyEdit:SetSize(610, 285); self.copyEdit:SetPoint("TOPLEFT")
        self.copyEdit:SetScript("OnEscapePressed", function() self.copy:Hide() end)
        self.copyEdit:SetScript("OnTextChanged", function(edit) scroll.content:SetHeight(math.max(285, edit:GetHeight())) end)
    end
    self.copy:Show(); self.copyEdit:SetText(text); self.copyEdit:HighlightText(); self.copyEdit:SetFocus()
end
function U:Summary(s)
    if not s then return "GrindMeter " .. G.version end
    local m = G.Calculator.Metrics(s, s.selectedNpcID, G.Storage.settings.method, self.revalued)
    return F.Plain(table.concat({"GrindMeter " .. G.version .. " | " .. s.selectedName .. " (NPC " .. s.selectedNpcID .. ")",
        F.Date(s.startedAt) .. " | " .. (s.zoneName or "") .. " | Lv " .. s.levelStart .. " | " .. s.groupInfo,
        G.L("measured") .. ": " .. F.Time(s.measuredSeconds) .. " | " .. G.L("pausedTime") .. ": " .. F.Time(s.pausedSeconds),
        m.kills .. " kills | " .. F.Number(m.killsHour) .. " kills/h | " .. F.Number(m.xpHour) .. " XP/h | " .. F.Gold(m.valuation.rate) .. " G/h",
        G.L(G.Storage.settings.method) .. " | " .. G.L("coins") .. ": " .. F.Money(m.valuation.coins),
        G.L("diagnosticsLine", s.unattributedXP, s.unattributedLoot, m.valuation.unknown, m.valuation.stale),
        G.L("rested") .. " | " .. G.L("restedStart") .. ": " .. (s.restedInfo or 0), G.L("extrapolated"), G.L("beforeCosts")}, "\n"))
end
function U:Toggle()
    if self.main:IsShown() then self.main:Hide() else self:Refresh(); self.main:Show() end
end
