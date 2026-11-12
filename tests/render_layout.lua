-- Export the actual UI frame tree to JSON for deterministic visual review.
-- Game textures/fonts and native tooltips are not emulated by the renderer.
local H = dofile("tests/harness.lua")
local G = H.setup(true)
G.eventFrame.scripts.OnEvent(G.eventFrame, "ADDON_LOADED", "GrindMeter")
G.UI:Toggle(); G.UI:ChooseTarget()
local function json(value)
    local kind = type(value)
    if kind == "string" then return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"' end
    if kind == "number" or kind == "boolean" then return tostring(value) end
    if kind == "nil" then return "null" end
    local result = {}
    if #value > 0 then
        for _, v in ipairs(value) do result[#result + 1] = json(v) end
        return "[" .. table.concat(result, ",") .. "]"
    end
    for k, v in pairs(value) do result[#result + 1] = json(k) .. ":" .. json(v) end
    return "{" .. table.concat(result, ",") .. "}"
end
local points = {TOPLEFT = {0, 0}, TOP = {.5, 0}, TOPRIGHT = {1, 0}, LEFT = {0, .5}, CENTER = {.5, .5}, RIGHT = {1, .5}, BOTTOMLEFT = {0, 1}, BOTTOM = {.5, 1}, BOTTOMRIGHT = {1, 1}}
local function export(root, file)
    local result, rects = {}, {}
    rects[root] = {x = 0, y = 0, w = root.width, h = root.height}
    local function rect(frame)
        if rects[frame] then return rects[frame] end
        local parent = frame.parent and rect(frame.parent) or {x = 0, y = 0, w = 860, h = 710}
        if frame.fillParent then rects[frame] = rect(frame.fillParent); return rects[frame] end
        local text = G.F.Plain(frame.text or ""):gsub("|H.-|h(.-)|h", "%1")
        local width, height = frame.width, frame.height
        if frame.kind == "FontString" then
            local size = frame.fontSize or 12
            width = width > 0 and width or #text * size * .5
            local _, breaks = text:gsub("\n", "")
            height = size * 1.35 * math.max(breaks + 1, math.ceil(#text * size * .47 / math.max(width, 1)))
        end
        local anchor = frame.anchor or {"TOPLEFT", frame.parent, "TOPLEFT", 0, 0}
        local relative = anchor[2] and rect(anchor[2]) or parent
        local a, b = points[anchor[1]] or points.TOPLEFT, points[anchor[3]] or points.TOPLEFT
        local r = {x = relative.x + relative.w * b[1] + anchor[4] - width * a[1], y = relative.y + relative.h * b[2] - anchor[5] - height * a[2], w = width, h = height}
        rects[frame] = r; return r
    end
    local function walk(frame)
        if not frame.shown then return end
        local r = rect(frame)
        if frame.bg or frame.text or frame.textureColor then
            result[#result + 1] = {x = r.x, y = r.y, w = r.w, h = r.h, kind = frame.kind, text = frame.kind == "FontString" and G.F.Plain(frame.text):gsub("|H.-|h(.-)|h", "%1") or nil,
                bg = frame.bg or frame.textureColor, color = frame.textColor, fontSize = frame.fontSize, align = frame.align, alpha = frame.alpha}
        end
        for _, child in ipairs(H.frames) do if child.parent == frame then walk(child) end end
    end
    walk(root)
    local out = assert(io.open(file, "w")); out:write(json({width = root.width, height = root.height, nodes = result})); out:close()
end
export(G.UI.main, "/tmp/grindmeter-setup.json")
G.UI.startButton:Click()
H.items[1688] = {name = "Long Soft Tail", vendor = 850, quality = 0}
for i = 1, 15 do
    H.at(i * 30)
    local name = i <= 6 and "Wildplains Huntress" or "Wildplains Patriarch"
    local id = i <= 6 and 259055 or 259054
    local guid = H.kill(G, id, i, name)
    G.Trackers:XP(name .. " dies, you gain 200 experience.", i, H.clock); G.Trackers:FlushXP(H.clock + 2)
    local link = H.link(1688)
    G.Trackers:OpenLoot(H.slot(G, guid, link, 1), H.clock)
    G.Trackers:Receipt(link, 1, 100 + i, H.clock); G.Trackers:ClearSlot(1); G.Trackers:CloseLoot(H.clock)
end
G.Session:Tick(H.at(600)); G.UI:Refresh()
export(G.UI.main, "/tmp/grindmeter-result.json")
export(G.UI.hud, "/tmp/grindmeter-hud.json")
G.UI.lootTab = "possible"; G.UI:Refresh()
export(G.UI.main, "/tmp/grindmeter-catalog.json")
print("Exported 4 UI layout states to /tmp/grindmeter-*.json (synthetic data).")
