local _, G = ...
local P = {}; G.Parser = P
local function literal(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
function P.Compile(format, unanchored)
    if type(format) ~= "string" then return nil end
    local pattern, fields, position, implicit = {}, {}, 1, 0
    while position <= #format do
        local first, last, index, kind = format:find("%%(%d+)%$([sd])", position)
        local a, b, simple = format:find("%%([sd])", position)
        if a and (not first or a < first) then first, last, index, kind = a, b, nil, simple end
        if not first then pattern[#pattern + 1] = literal(format:sub(position)); break end
        pattern[#pattern + 1] = literal(format:sub(position, first - 1))
        implicit = implicit + 1
        fields[#fields + 1] = {index = tonumber(index) or implicit, kind = kind}
        pattern[#pattern + 1] = kind == "d" and "([%d%.,]+)" or "(.-)"
        position = last + 1
    end
    return {pattern = (unanchored and "" or "^") .. table.concat(pattern) .. (unanchored and "" or "$"), fields = fields}
end
function P.Match(compiled, message)
    if not compiled then return nil end
    local captured = {message:match(compiled.pattern)}
    if #captured == 0 then return nil end
    local values = {}
    for i, field in ipairs(compiled.fields) do
        local value = captured[i]
        if field.kind == "d" then value = tonumber(((value or ""):gsub("[^%d]", ""))) end
        values[field.index] = value
    end
    return values
end
function P:Initialize(globals)
    self.xp = {}; self.loot = {}; self.money = {}; self.denominations = {}
    for name, format in pairs(globals) do
        if type(name) == "string" and type(format) == "string" and name:match("^COMBATLOG_XPGAIN_")
            and (name:find("FIRSTPERSON", 1, true) or name:find("EXHAUSTION", 1, true)) then
            self.xp[#self.xp + 1] = {name = name, compiled = P.Compile(format)}
        end
    end
    for _, name in ipairs({"LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF"}) do
        if globals[name] then self.loot[#self.loot + 1] = P.Compile(globals[name]) end
    end
    for _, name in ipairs({"YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT", "YOU_LOOT_MONEY_GUILD", "LOOT_MONEY_SPLIT_GUILD"}) do
        if globals[name] then self.money[#self.money + 1] = P.Compile(globals[name]) end
    end
    for _, row in ipairs({{"GOLD_AMOUNT", 10000}, {"SILVER_AMOUNT", 100}, {"COPPER_AMOUNT", 1},
        {"GOLD_AMOUNT_SYMBOL", 10000}, {"SILVER_AMOUNT_SYMBOL", 100}, {"COPPER_AMOUNT_SYMBOL", 1}}) do
        local format = globals[row[1]]
        if type(format) == "string" and format:find("%%") then
            self.denominations[#self.denominations + 1] = {compiled = P.Compile(format, true), multiplier = row[2]}
        end
    end
end
function P:XP(message)
    for _, parser in ipairs(self.xp) do
        local fields = P.Match(parser.compiled, message)
        if fields then
            -- Named kill XP has mob name at argument 1 and total awarded XP at argument 2.
            if type(fields[1]) == "string" and type(fields[2]) == "number" then
                return {name = fields[1], amount = fields[2], format = parser.name}
            end
            return {unclassified = true, amount = type(fields[1]) == "number" and fields[1] or 0}
        end
    end
end
function P:Loot(message)
    for _, parser in ipairs(self.loot) do
        local fields = P.Match(parser, message)
        if fields and G.ItemKey(fields[1]) then return fields[1], fields[2] or 1 end
    end
end
function P:Money(message)
    local moneyText
    for _, parser in ipairs(self.money) do
        local fields = P.Match(parser, message)
        if fields then moneyText = fields[1]; break end
    end
    if type(moneyText) ~= "string" then return nil end
    if type(GetMoneyFromString) == "function" then
        local ok, amount = pcall(GetMoneyFromString, moneyText)
        if ok and type(amount) == "number" and amount > 0 then return amount end
    end
    local total, found, denominations = 0, false, {}
    for _, row in ipairs(self.denominations) do
        if not denominations[row.multiplier] then
            local fields = P.Match(row.compiled, moneyText)
            if fields and type(fields[1]) == "number" then
                total = total + fields[1] * row.multiplier; found = true; denominations[row.multiplier] = true
            end
        end
    end
    return found and total or nil
end
