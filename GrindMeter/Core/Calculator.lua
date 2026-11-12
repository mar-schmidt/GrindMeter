local _, G = ...
local C = {}; G.Calculator = C
function C.Rate(amount, seconds)
    if not seconds or seconds <= 0 or amount == nil then return nil end
    return amount * 3600 / seconds
end
function C.NetAH(price, fee)
    if price == nil then return nil end
    -- Keep fractional copper until presentation. This is a sale model, not an AH settlement.
    return price * (1 - fee)
end
function C.ItemValue(price, method, fee)
    price = price or {}
    local vendor = price.vendor
    local auction = price.tradeEligible == true and price.ah and C.NetAH(price.ah.unitPriceCopper, fee) or nil
    if method == "vendor" then return vendor, vendor ~= nil and "vendor" or "unknown" end
    if auction ~= nil and (vendor == nil or auction > vendor) then return auction, "AH" end
    return vendor, vendor ~= nil and "vendor" or "unknown"
end
function C.PriceBreakdown(price, quantity, method, fee)
    local unit, via = C.ItemValue(price, method, fee)
    local gross = price.ah and price.ah.unitPriceCopper or nil
    return {quantity = quantity, unit = unit, via = via, total = unit and quantity * unit or nil,
        grossUnit = gross, grossTotal = gross and gross * quantity or nil,
        feeTotal = gross and gross * quantity * fee or nil,
        netTotal = gross and price.tradeEligible == true and gross * quantity * (1 - fee) or nil,
        vendorTotal = price.vendor and price.vendor * quantity or nil}
end
function C.Value(session, npcID, method, prices)
    local result = {value = 0, coins = 0, unknown = 0, stale = 0, ahMissing = 0, count = 0}
    for source, copper in pairs(session.coinsByNpcID or {}) do
        if not npcID or source == npcID then result.coins = result.coins + copper end
    end
    result.value = result.coins
    for _, receipt in ipairs(session.lootReceipts or {}) do
        if receipt.sourceNpcID and (not npcID or receipt.sourceNpcID == npcID) and receipt.category == "normal" then
            local p = (prices or session.priceSnapshot or {})[receipt.variantKey] or {}
            local unit = C.ItemValue(p, method, session.fee or .05)
            result.count = result.count + receipt.quantity
            if unit == nil then result.unknown = result.unknown + receipt.quantity
            else result.value = result.value + receipt.quantity * unit end
            if p.ah and p.ah.stale then result.stale = result.stale + receipt.quantity end
            if method ~= "vendor" and p.tradeEligible ~= false and not p.ah then result.ahMissing = result.ahMissing + receipt.quantity end
        end
    end
    result.partial = result.unknown > 0 or session.unattributedLoot > 0 or session.unattributedMoney > 0
        or session.lootSourceAvailable == false or session.lootUnavailable == true or session.moneyUnavailable == true
    result.rate = C.Rate(result.value, session.measuredSeconds)
    return result
end
function C.Metrics(session, npcID, method, prices)
    local kills, xp, matched = 0, 0, 0
    for id, counter in pairs(session.countersByNpcID) do
        if not npcID or id == npcID then
            kills = kills + counter.kills; xp = xp + counter.xp; matched = matched + (counter.xpKills or 0)
        end
    end
    local xpKnown = session.xpAvailable == true
    local xpPartial = session.unattributedXP > 0 or (not session.xpZeroExpected and matched < kills)
    return {kills = kills, xp = xp, killsHour = session.killAvailable and C.Rate(kills, session.measuredSeconds) or nil,
        xpHour = xpKnown and C.Rate(xp, session.measuredSeconds) or nil,
        xpPartial = xpPartial, secondsKill = kills > 0 and session.measuredSeconds / kills or nil,
        preliminary = session.measuredSeconds < 300 or kills < 10,
        valuation = C.Value(session, npcID, method, prices)}
end
function C.Forecast(entries, killsHour, getPrice, fee, coinMean)
    local value, covered, missing = coinMean or 0, 0, 0
    for _, item in ipairs(entries or {}) do
        if item.category == "normal" and not item.condition then
            local units = item.expectedUnits or (item.probability and item.meanQuantity and item.probability * item.meanQuantity)
            local price = getPrice(item)
            if units and price ~= nil then value = value + units * price; covered = covered + 1
            else missing = missing + 1 end
        end
    end
    return {value = covered > 0 and killsHour and killsHour * value or nil,
        covered = covered, missing = missing, partial = missing > 0 or coinMean == nil}
end
function C.Observed(bodies, hits, units)
    if not bodies or bodies == 0 then return nil end
    return hits / bodies, units / bodies
end
