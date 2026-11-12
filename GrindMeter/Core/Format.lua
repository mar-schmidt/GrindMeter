local _, G = ...
G.F = {}
function G.F.Time(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end
function G.F.Number(n)
    if n == nil then return "-" end
    return string.format(n >= 1000 and "%.0f" or "%.1f", n)
end
function G.F.Money(copper)
    if copper == nil then return "-" end
    copper = math.floor(copper + 0.5)
    return string.format("|cffffd26a%dg|r |cffc5cbd4%ds|r |cffcb9970%dc|r", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end
function G.F.Gold(copper)
    return copper and string.format("%.2f", copper / 10000) or "-"
end
function G.F.Date(timestamp)
    return date("%Y-%m-%d %H:%M", timestamp or time())
end
function G.F.Plain(value)
    return tostring(value or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
