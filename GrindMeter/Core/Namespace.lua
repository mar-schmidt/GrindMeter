local _, G = ...
G.version = "0.1.2"
G.schema = 1
G.icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
G.modules = {}
function G.Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for k, v in pairs(value) do result[G.Copy(k, seen)] = G.Copy(v, seen) end
    return result
end
function G.NpcID(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end
function G.ItemKey(link)
    if type(link) ~= "string" then return nil end
    -- Retain the entire payload, including suffix, unique ID and bonuses.
    return link:match("|H(item:[^|]+)|h") or link:match("^(item:[^|]+)$")
end
function G.ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end
function G.Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffdfb76bGrindMeter|r  " .. text) end
end
