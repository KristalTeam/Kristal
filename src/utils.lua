local Utils = {}

function Utils.copy(tbl, deep)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        if type(v) == "table" and deep then
            new_tbl[k] = Utils.copy(v, true)
        else
            new_tbl[k] = v
        end
    end
    return new_tbl
end

local function dumpKey(key)
    if type(key) == 'table' then
        return '('..tostring(key)..')'
    elseif type(key) == 'string' and not key:find("[^%a_%-]") then
        return key
    else
        return '['..Utils.dump(key)..']'
    end
end

function Utils.dump(o)
    if type(o) == 'table' then
        local s = '{'
        local cn = 1
        if #o ~= 0 then
            for _,v in ipairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. Utils.dump(v)
                cn = cn + 1
            end
        else
            for k,v in pairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. dumpKey(k) .. ' = ' .. Utils.dump(v)
                cn = cn + 1
            end
        end
        return s .. '}'
    elseif type(o) == 'string' then
        return '"' .. o .. '"'
    else
        return tostring(o)
    end
end

function Utils.splitFast(str, sep)
    local t={} ; i=1
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function Utils.split(str, sep, remove_empty)
    local t = {}
    local i = 1
    local s = ""
    while i <= #str do
        if str:sub(i, i + (#sep - 1)) == sep then
            if not remove_empty or s ~= "" then
                table.insert(t, s)
            end
            s = ""
            i = i + (#sep - 1)
        else
            s = s .. str:sub(i, i)
        end
        i = i + 1
    end
    if not remove_empty or s ~= "" then
        table.insert(t, s)
    end
    return t
end

function Utils.join(tbl, sep, start, len)
    local s = ""
    local n = start or 1
    for i = n, (len or #tbl) do
        if i == n then
            s = s..tbl[i]
        else
            s = s..sep..tbl[i]
        end
    end
    return s
end

function Utils.hook(target, func)
    return function(...)
        return func(target, ...)
    end
end

function Utils.equal(a, b, deep)
    if type(a) ~= type(b) then
        return false
    elseif type(a) == "table" then
        for k,v in pairs(a) do
            if b[k] == nil then
                return false
            elseif deep and not Utils.equal(v, b[k]) then
                return false
            elseif not deep and v ~= b[k] then
                return false
            end
        end
        for k,v in pairs(b) do
            if a[k] == nil then
                return false
            end
        end
    elseif a ~= b then
        return false
    end
    return true
end

function Utils.getFilesRecursive(dir, ext)
    local result = {}

    local paths = love.filesystem.getDirectoryItems(dir)
    for _,path in ipairs(paths) do
        local info = love.filesystem.getInfo(dir.."/"..path)
        if info then
            if info.type == "directory" then
                local inners = Utils.getFilesRecursive(dir.."/"..path, ext)
                for _,inner in ipairs(inners) do
                    table.insert(result, path.."/"..inner)
                end
            elseif not ext or path:sub(-#ext) == ext then
                table.insert(result, ext and path:sub(1, -#ext-1) or path)
            end
        end
    end

    return result
end

function Utils.getCombinedText(text)
    if type(text) == "table" then
        local s = ""
        for _,v in ipairs(text) do
            if type(v) == "string" then
                s = s .. v
            end
        end
        return s
    else
        return tostring(text)
    end
end


-- https://github.com/Wavalab/rgb-hsl-rgb
function Utils.hslToRgb(h, s, l)
    if s == 0 then return l, l, l end
    local function to(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < .16667 then return p + (q - p) * 6 * t end
        if t < .5 then return q end
        if t < .66667 then return p + (q - p) * (.66667 - t) * 6 end
        return p
    end
    local q = l < .5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    return to(p, q, h + .33334), to(p, q, h), to(p, q, h - .33334)
end

function Utils.rgbToHsl(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local b = max + min
    local h = b / 2
    if max == min then return 0, 0, h end
    local s, l = h, h
    local d = max - min
    s = l > .5 and d / (2 - b) or d / b
    if max == r then h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    return h * .16667, s, l
end

-- https://github.com/s-walrus/hex2color
function Utils.hexToRgb(hex, value)
    return {tonumber(string.sub(hex, 2, 3), 16)/256, tonumber(string.sub(hex, 4, 5), 16)/256, tonumber(string.sub(hex, 6, 7), 16)/256, value or 1}
end

function Utils:rgbToHex(rgb)
    return string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3])
end

function Utils.merge(tbl, other, deep)
    if #tbl > 0 and #other > 0 then
        for _,v in ipairs(other) do
            table.insert(tbl, v)
        end
    else
        for k,v in pairs(other) do
            if deep and type(tbl[k]) == "table" and type(v) == "table" then
                Utils.merge(tbl[k], v, true)
            else
                tbl[k] = v
            end
        end
    end
    return tbl
end

function Utils.removeFromTable(tbl, val)
    for i,v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return v
        end
    end
end

function Utils.containsValue(tbl, val)
    for k,v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

function Utils.round(value)
    return math.floor(value + 0.5)
end

function Utils.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function Utils.sign(num)
    return num > 0 and 1 or (num < 0 and -1 or 0)
end

function Utils.approach(val, target, amount)
    if target < val then
        return math.max(target, val - amount)
    elseif target > val then
        return math.min(target, val + amount)
    end
    return target
end

function Utils.lerp(a, b, t)
    return a + (b - a) * Utils.clamp(t, 0, 1)
end

local performance_stack = {}

function Utils.pushPerformance(name)
    table.insert(performance_stack, 1, {love.timer.getTime(), name})
end

function Utils.popPerformance()
    local c = love.timer.getTime()
    local t = table.remove(performance_stack, 1)
    local name = t[2]
    if PERFORMANCE_TEST then
        PERFORMANCE_TEST[name] = PERFORMANCE_TEST[name] or {}
        table.insert(PERFORMANCE_TEST[name], c - t[1])
    end
end

function Utils.printPerformance()
    for k,times in pairs(PERFORMANCE_TEST) do
        if k ~= "Total" and #times > 0 then
            local n = 0
            for _,v in ipairs(times) do
                n = n + v
            end
            print("["..PERFORMANCE_TEST_STAGE.."] "..k.. " | "..#times.." calls | "..(n / #times).." | Total: "..n)
        end
    end
    if PERFORMANCE_TEST["Total"] then
        print("["..PERFORMANCE_TEST_STAGE.."] Total: "..PERFORMANCE_TEST["Total"][1])
    end
end

function Utils.merge_color(start_color, end_color, amount)
    local color = {
        Utils.lerp(start_color[1],      end_color[1],      amount),
        Utils.lerp(start_color[2],      end_color[2],      amount),
        Utils.lerp(start_color[3],      end_color[3],      amount),
        Utils.lerp(start_color[4] or 1, end_color[4] or 1, amount)
    }
    return color
end


return Utils