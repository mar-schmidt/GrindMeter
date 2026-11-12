local _, G = ...
G.Catalog = {version = "2026-11-12.1", gameFlavor = "forever", referenceCount = 2,
    references = {
        [259055] = {name = "Wildplains Huntress", coverage = "missing", checkedAt = "2026-11-12",
            source = "https://db.icy-veins.com/wow-forever/npcs/259055"},
        [259054] = {name = "Wildplains Patriarch", coverage = "missing", checkedAt = "2026-11-12",
            source = "https://db.icy-veins.com/wow-forever/npcs/259054"},
    }, entries = {}}
-- Identity references only: no third-party drop database is redistributed.
-- Player-confirmed discoveries are stored separately, per character and NPC ID.
function G.Catalog:Get(npcID)
    local rows, learned = {}, G.Storage.character.catalog[npcID]
    for _, row in ipairs(self.entries[npcID] or {}) do rows[#rows + 1] = G.Copy(row) end
    if learned then
        for _, row in pairs(learned.items) do
            local copy = G.Copy(row); copy.source = "own-observations"; copy.category = copy.category or "normal"
            rows[#rows + 1] = copy
        end
    end
    return rows, #rows > 0 and "partial" or "missing"
end
function G.Catalog:Learn(session)
    for npcID, observations in pairs(session.bodyObservations or {}) do
        local character = G.Storage.character
        local catalog = character.catalog[npcID] or {bodies = 0, items = {}}
        character.catalog[npcID] = catalog
        for _, body in pairs(observations) do
            if body.qualified then
                catalog.bodies = catalog.bodies + 1
                for key, item in pairs(body.items) do
                    local entry = catalog.items[key] or {itemID = item.itemID, itemLink = item.itemLink,
                        variantKey = key, hits = 0, units = 0, category = "normal"}
                    catalog.items[key] = entry
                    entry.hits = entry.hits + 1; entry.units = entry.units + item.quantity
                    entry.lastSeenAt = session.endedAt
                end
            end
        end
        for _, item in pairs(catalog.items) do item.bodies = catalog.bodies end
    end
end
