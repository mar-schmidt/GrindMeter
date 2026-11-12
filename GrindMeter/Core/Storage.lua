local _, G = ...
local S = {}; G.Storage = S
local defaults = {language = "sv", duration = 600, method = "vendor", showMinimap = true, showHUD = true,
    minimapAngle = 215, fee = .05, staleHours = 24}
local function valid(session)
    local base = type(session) == "table" and session.schemaVersion == G.schema and type(session.id) == "string"
        and type(session.selectedNpcID) == "number" and type(session.countersByNpcID) == "table"
        and type(session.lootReceipts) == "table" and type(session.measuredSeconds) == "number"
        and type(session.priceSnapshot) == "table" and type(session.coinsByNpcID) == "table"
        and type(session.selectedName) == "string" and type(session.startedAt) == "number"
        and type(session.levelStart) == "number" and type(session.duration) == "number"
        and type(session.pausedSeconds) == "number" and type(session.unattributedXP) == "number"
        and type(session.unattributedLoot) == "number" and type(session.unattributedMoney) == "number"
        and type(session.diagnosticsSummary) == "table" and type(session.fee) == "number"
    if not base then return false end
    for id, counter in pairs(session.countersByNpcID) do
        if type(id) ~= "number" or type(counter) ~= "table" or type(counter.kills) ~= "number"
            or type(counter.xp) ~= "number" or type(counter.name) ~= "string" then return false end
    end
    for _, receipt in ipairs(session.lootReceipts) do
        if type(receipt) ~= "table" or type(receipt.itemLink) ~= "string" or not G.ItemID(receipt.itemLink)
            or type(receipt.quantity) ~= "number" or receipt.quantity <= 0 or type(receipt.variantKey) ~= "string" then return false end
    end
    for _, price in pairs(session.priceSnapshot) do if type(price) ~= "table" then return false end end
    for _, copper in pairs(session.coinsByNpcID) do if type(copper) ~= "number" then return false end end
    return true
end
function S:Initialize(context)
    local db = GrindMeterDB
    if type(db) ~= "table" or db.schemaVersion ~= G.schema then db = {schemaVersion = G.schema} end
    db.settings = type(db.settings) == "table" and db.settings or {}
    for k, value in pairs(defaults) do if type(db.settings[k]) ~= type(value) then db.settings[k] = value end end
    if db.settings.language ~= "sv" and db.settings.language ~= "en" then db.settings.language = "sv" end
    db.settings.fee = math.max(0, math.min(.5, db.settings.fee))
    db.settings.staleHours = math.max(1, math.min(720, db.settings.staleHours))
    db.characters = type(db.characters) == "table" and db.characters or {}
    local key = context.characterKey
    local character = type(db.characters[key]) == "table" and db.characters[key] or {}
    db.characters[key] = character
    character.catalog = type(character.catalog) == "table" and character.catalog or {}
    for id, catalog in pairs(character.catalog) do
        if type(id) ~= "number" or type(catalog) ~= "table" or type(catalog.items) ~= "table" or type(catalog.bodies) ~= "number" then
            character.catalog[id] = nil
        else
            for key, item in pairs(catalog.items) do
                if type(item) ~= "table" or type(item.itemID) ~= "number" or type(item.hits) ~= "number" or type(item.units) ~= "number" then catalog.items[key] = nil end
            end
        end
    end
    local clean = {}
    for _, session in ipairs(type(character.history) == "table" and character.history or {}) do
        if valid(session) and #clean < 50 then
            local good = true
            for _, c in pairs(session.countersByNpcID) do
                if type(c) ~= "table" or type(c.kills) ~= "number" or type(c.xp) ~= "number" then good = false end
            end
            if good then clean[#clean + 1] = session end
        end
    end
    character.history = clean
    if not valid(character.active) then character.active = nil end
    GrindMeterDB = db; self.db = db; self.settings = db.settings; self.character = character
end
function S:Add(session)
    table.insert(self.character.history, 1, session)
    while #self.character.history > 50 do table.remove(self.character.history) end
    self.character.active = nil
end
function S:Delete(id)
    for i, session in ipairs(self.character.history) do
        if session.id == id then table.remove(self.character.history, i); return true end
    end
end
