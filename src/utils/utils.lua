local Utils = {}

function Utils.sub(s,i,j)
    i = i or 1
    j = j or -1
    if i<1 or j<1 then
        local n = utf8.len(s)
        if not n then return nil end
        if i<0 then i = n+1+i end
        if j<0 then j = n+1+j end
        if i<0 then i = 1 end
        if j<0 then j = 1 end
        if j<i then return "" end
        if i>n then i = n end
        if j>n then j = n end
    end
    if j<i then return "" end
    i = utf8.offset(s,i)
    j = utf8.offset(s,j+1)
    if i and j then return string.sub(s,i,j-1)
       elseif i then return string.sub(s,i)
       else return ""
    end
 end

function Utils.all(tbl, func)
    if not func then
        for i = 1, #tbl do
            if not tbl[i] then
                return false
            end
        end
    else
        for i = 1, #tbl do
            if not func(tbl[i]) then
                return false
            end
        end
    end
    return true
end

function Utils.any(tbl, func)
    if not func then
        for i = 1, #tbl do
            if tbl[i] then
                return true
            end
        end
    else
        for i = 1, #tbl do
            if func(tbl[i]) then
                return true
            end
        end
    end
    return false
end

function Utils.copy(tbl, deep, seen)
    if tbl == nil then return nil end
    local new_tbl = {}
    return Utils.copyInto(new_tbl, tbl, deep, seen)
end

function Utils.copyInto(new_tbl, tbl, deep, seen)
    if tbl == nil then return nil end
    seen = seen or {}
    seen[tbl] = new_tbl
    for k,v in pairs(tbl) do
        if type(v) == "table" and deep then
            if seen[v] then
                new_tbl[k] = seen[v]
            elseif (not isClass(v) or (v.canDeepCopy and v:canDeepCopy())) and (not isClass(tbl) or (tbl:canDeepCopyKey(k) and not tbl.__dont_include[k])) then
                new_tbl[k] = {}
                Utils.copyInto(new_tbl[k], v, true, seen)
            else
                new_tbl[k] = v
            end
        else
            new_tbl[k] = v
        end
    end
    setmetatable(new_tbl, getmetatable(tbl))
    if new_tbl.onClone then
        new_tbl:onClone(tbl)
    end
    return new_tbl
end

function Utils.clear(tbl)
    for key in pairs (tbl) do
        tbl[key] = nil
    end
end

function Utils.getClassName(class, parent_check)
    for k,v in pairs(_G) do
        if class.__index == v then
            return k
        end
    end
    for k,v in ipairs(class.__includes) do
        local name = Utils.getClassName(v, true)
        if name then
            if not parent_check and class.id then
                return name .. "(" .. class.id .. ")"
            else
                return name
            end
        end
    end
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
        if isClass(o) then
            return Utils.getClassName(o)
        end
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

function Utils.unpack(t)
    return unpack(t, 1, table.maxn(t))
end

function Utils.coloredToString(colored)
    if type(colored) == "string" then
        return colored
    end
    local str = ""
    for line, text in ipairs(colored) do
        if type(text) == "string" then
            str = str .. text
        end
    end
    return str
end

function Utils.splitFast(str, sep)
    local t={} ; local i=1
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
    while i <= utf8.len(str) do
        if Utils.sub(str, i, i + (utf8.len(sep) - 1)) == sep then
            if not remove_empty or s ~= "" then
                table.insert(t, s)
            end
            s = ""
            i = i + (#sep - 1)
        else
            s = s .. Utils.sub(str, i, i)
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

Utils.__MOD_HOOKS = {}
function Utils.hook(target, name, hook, exact_func)
    local orig = target[name]
    if Mod then
        table.insert(Utils.__MOD_HOOKS, 1, {target = target, name = name, hook = hook, orig = orig})
    end
    local orig_func = orig or function() end
    if not exact_func then
        target[name] = function(...)
            return hook(orig_func, ...)
        end
    else
        target[name] = hook
    end
    if isClass(target) then
        for _,includer in ipairs(target.__includers or {}) do
            if includer[name] == orig then
                Utils.hook(includer, name, target[name], true)
            end
        end
    end
end

function Utils.override(old_func, new_func)
    old_func = old_func or function() end
    return function(...)
        return new_func(old_func, ...)
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

-- https://love2d.org/wiki/HSV_color
function Utils.hsvToRgb(h, s, v)
    if s <= 0 then return v,v,v end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r+m, g+m, b+m
end

-- https://github.com/s-walrus/hex2color
function Utils.hexToRgb(hex, value)
    return {tonumber(string.sub(hex, 2, 3), 16)/256, tonumber(string.sub(hex, 4, 5), 16)/256, tonumber(string.sub(hex, 6, 7), 16)/256, value or 1}
end

function Utils.rgbToHex(rgb)
    return string.format("#%02X%02X%02X", rgb[1]*255, rgb[2]*255, rgb[3]*255)
end

function Utils.parseColorProperty(property)
    local str = "#"..string.sub(property, 4)
    local a = tonumber(string.sub(property, 2, 3), 16)/256
    return Utils.hexToRgb(str, a)
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

function Utils.mergeMultiple(...)
    local tbl = {}
    for _,other in ipairs{...} do
        Utils.merge(tbl, other)
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

function Utils.floor(value, to)
    if not to then
        return math.floor(value)
    elseif to == 0 then
        return 0
    else
        return math.floor(value/to)*to
    end
end

function Utils.ceil(value, to)
    if not to then
        return math.ceil(value)
    elseif to == 0 then
        return 0
    else
        return math.ceil(value/to)*to
    end
end

function Utils.round(value, to)
    if not to then
        return math.floor(value + 0.5)
    else
        return math.floor((value + (to/2)) / to) * to
    end
end

function Utils.roundToZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.floor(value) end
    if value < 0 then return math.ceil(value) end
    return 0/0 -- return NaN lol
end

function Utils.roundFromZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.ceil(value) end
    if value < 0 then return math.floor(value) end
    return 0/0 -- return NaN lol
end

function Utils.roughEqual(a, b)
    return math.abs(a - b) < 0.01
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

function Utils.approachAngle(val, target, amount)
    local to = val + Utils.angleDiff(target, val)
    return Utils.approach(val, to, amount)
end

function Utils.lerp(a, b, t, oob)
    if type(a) == "table" and type(b) == "table" then
        local o = {}
        for k,v in ipairs(a) do
            table.insert(o, Utils.lerp(v, b[k] or v, t))
        end
        return o
    else
        return a + (b - a) * (oob and t or Utils.clamp(t, 0, 1))
    end
end

function Utils.lerpPoint(x1, y1, x2, y2, t, oob)
    return Utils.lerp(x1, x2, t, oob), Utils.lerp(y1, y2, t, oob)
end

function Utils.ease(a, b, t, mode)
    if t >= 1 then
        return b
    else
        return Ease[mode](Utils.clamp(t, 0, 1), a, (b - a), 1)
    end
end

function Utils.clampMap(val, min_a, max_a, min_b, max_b, mode)
    if min_a > max_a then
        min_a, max_a = max_a, min_a
        min_b, max_b = max_b, min_b
    end
    val = Utils.clamp(val, min_a, max_a)
    local t = (val - min_a) / (max_a - min_a)
    if mode and mode ~= "linear" then
        return Utils.ease(min_b, max_b, t, mode)
    else
        return Utils.lerp(min_b, max_b, t)
    end
end

function Utils.wave(val, min, max)
    return Utils.clampMap(math.sin(val), -1,1, min or -1,max or 1)
end

function Utils.between(val, a, b, include)
    if include then
        if a < b then
            return val >= a and val <= b
        else
            return val >= b and val <= a
        end
    else
        if a < b then
            return val > a and val < b
        else
            return val > b and val < a
        end
    end
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

function Utils.mergeColor(start_color, end_color, amount)
    local color = {
        Utils.lerp(start_color[1],      end_color[1],      amount),
        Utils.lerp(start_color[2],      end_color[2],      amount),
        Utils.lerp(start_color[3],      end_color[3],      amount),
        Utils.lerp(start_color[4] or 1, end_color[4] or 1, amount)
    }
    return color
end

function Utils.getPolygonEdges(points)
    local edges = {}
    for i = 1, #points do
        local p1, p2 = points[i], points[(i % #points) + 1]
        table.insert(edges, {p1, p2, angle=math.atan2(p2[2] - p1[2], p2[1] - p1[1])})
    end
    return edges
end

function Utils.isPolygonClockwise(edges)
    local sum = 0
    for _,edge in ipairs(edges) do
        sum = sum + ((edge[2][1] - edge[1][1]) * (edge[2][2] + edge[1][2]))
    end
    return sum > 0
end

function Utils.getLineIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
    local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
    local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
    local det = a1*b2 - a2*b1
    if det==0 then return false, "The lines are parallel." end
    local x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
    if seg1 or seg2 then
        local min,max = math.min, math.max
        if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p2y) <= y and y <= max(l1p1y,l1p2y)) or
           seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
            return false, "The lines don't intersect."
        end
    end
    return x,y
end

function Utils.getPolygonOffset(points, dist)
    local edges = Utils.getPolygonEdges(points)
    local sign = Utils.isPolygonClockwise(edges) and 1 or -1

    local function offsetPoint(x, y, angle, dist)
        return x + math.cos(angle) * dist, y + math.sin(angle) * dist
    end

    local new_polygon = {}
    for i = 1, #edges do
        local e1, e2 = edges[i], edges[(i % #edges) + 1]

        local p1x, p1y = offsetPoint(e1[1][1], e1[1][2], e1.angle + sign * (math.pi/2), dist)
        local p2x, p2y = offsetPoint(e1[2][1], e1[2][2], e1.angle + sign * (math.pi/2), dist)
        local p3x, p3y = offsetPoint(e2[1][1], e2[1][2], e2.angle + sign * (math.pi/2), dist)
        local p4x, p4y = offsetPoint(e2[2][1], e2[2][2], e2.angle + sign * (math.pi/2), dist)

        local ix, iy = Utils.getLineIntersect(p1x,p1y, p2x,p2y, p3x,p3y, p4x,p4y)
        if ix then
            table.insert(new_polygon, {ix, iy})
        end
    end

    table.insert(new_polygon, 1, table.remove(new_polygon, #new_polygon))

    return new_polygon
end

function Utils.unpackPolygon(points)
    local line = {}
    for _,point in ipairs(points) do
        table.insert(line, point[1])
        table.insert(line, point[2])
    end
    table.insert(line, points[1][1])
    table.insert(line, points[1][2])
    return unpack(line)
end

function Utils.unpackColor(color)
    return color[1], color[2], color[3], color[4] or 1
end

function Utils.random(a, b, c)
    if not a then
        return love.math.random()
    elseif not b then
        return love.math.random() * a
    else
        local n = love.math.random() * (b - a) + a
        if c then
            n = Utils.round(n, c)
        end
        return n
    end
end

function Utils.randomSign()
    return love.math.random() < 0.5 and 1 or -1
end

function Utils.randomAxis()
    local t = {Utils.randomSign()}
    table.insert(t, love.math.random(2), 0)
    return t
end

function Utils.filter(tbl, filter)
    local t = {}
    for _,v in ipairs(tbl) do
        if filter(v) then
            table.insert(t, v)
        end
    end
    return t
end

function Utils.filterInPlace(tbl, filter)
    local i = 1
    while i <= #tbl do
        if not filter(tbl[i]) then
            table.remove(tbl, i)
        else
            i = i + 1
        end
    end
end

function Utils.pick(tbl, sort)
    tbl = sort and Utils.filter(tbl, sort) or tbl
    return tbl[love.math.random(#tbl)]
end

function Utils.pickMultiple(tbl, amount, sort)
    tbl = sort and Utils.filter(tbl, sort) or Utils.copy(tbl)
    local t = {}
    for _=1,amount do
        local i = love.math.random(#tbl)
        table.insert(t, tbl[i])
        table.remove(tbl, i)
    end
    return t
end

function Utils.shuffle(tbl)
    return Utils.pickMultiple(tbl, #tbl)
end

function Utils.reverse(tbl)
    local t = {}
    for i=#tbl,1,-1 do
        table.insert(t, tbl[i])
    end
    return t
end

function Utils.angle(x1,y1, x2,y2)
    if isClass(x1) and isClass(y1) and x1:includes(Object) and y1:includes(Object) then
        local obj1, obj2 = x1, y1
        return math.atan2(obj2.y - obj1.y, obj2.x - obj1.x)
    else
        return math.atan2(y2 - y1, x2 - x1)
    end
end

function Utils.angleDiff(a, b)
    local r = a - b
    return (r + math.pi) % (math.pi*2) - math.pi
end

function Utils.dist(x1,y1, x2,y2)
    local dx, dy = x1-x2, y1-y2
    return math.sqrt(dx*dx + dy*dy)
end

function Utils.contains(str, filter)
    return string.find(str, filter) ~= nil
end

function Utils.startsWith(value, prefix)
    if type(value) == "string" then
        if value:sub(1, #prefix) == prefix then
            return true, value:sub(#prefix + 1)
        else
            return false, value
        end
    elseif type(value) == "table" then
        if #value >= #prefix then
            local copy = Utils.copy(value)
            for i,v in ipairs(value) do
                if prefix[i] ~= v then
                    return false, value
                end
                table.remove(copy, 1)
            end
            return true, copy
        end
    end
    return false, value
end

function Utils.endsWith(value, suffix)
    if type(value) == "string" then
        if value:sub(-#suffix) == suffix then
            return true, value:sub(1, -#suffix - 1)
        else
            return false, value
        end
    elseif type(value) == "table" then
        if #value >= #suffix then
            local copy = Utils.copy(value)
            for i = #value, 1, -1 do
                if suffix[#suffix + (i - #value)] ~= copy[i] then
                    return false, value
                end
                table.remove(copy, i)
            end
            return true, copy
        end
    end
    return false, value
end

function Utils.absoluteToLocalPath(prefix, image, path)
    local current_path = Utils.split(path, "/")
    local tileset_path = Utils.split(image, "/")
    while tileset_path[1] == ".." do
        table.remove(tileset_path, 1)
        table.remove(current_path, #current_path)
    end
    Utils.merge(current_path, tileset_path)
    local final_path = table.concat(current_path, "/")
    local _,ind = final_path:find(prefix)
    if not ind then return false end
    final_path = final_path:sub(ind + 1)
    local ext = final_path
    while ext:find("%.") do
        _,ind = ext:find("%.")
        if not ind then return false end
        ext = ext:sub(ind + 1)
    end
    if ext == final_path then
        return final_path
    else
        return final_path:sub(1, -#ext - 2)
    end
end

function Utils.titleCase(str)
    local buf = {}
    for word in string.gfind(str, "%S+") do
        local first, rest = string.sub(word, 1, 1), string.sub(word, 2)
        table.insert(buf, string.upper(first) .. string.lower(rest))
    end
    return table.concat(buf, " ")
end

function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function Utils.keyFromNumber(t, number)
    local count = 1
    for key, value in pairs(t) do
        if count == number then
            return key
        end
        count = count + 1
    end
    return nil
end

function Utils.numberFromKey(t, name)
    local count = 1
    for key, value in pairs(t) do
        if key == name then
            return count
        end
        count = count + 1
    end
    return nil
end

function Utils.getIndex(t, value)
    for i,v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

function Utils.getKey(t, value)
    for key, v in pairs(t) do
        if v == value then
            return key
        end
    end
    return nil
end

function Utils.getAnyCase(t, key)
    for k,v in pairs(t) do
        if type(k) == "string" and k:lower() == key:lower() then
            return v
        end
    end
    return nil
end

function Utils.absClamp(value, min, max)
    local sign = value < 0 and -1 or 1
    return math.max(min, math.min(max, math.abs(value))) * sign
end

function Utils.absMin(a, b)
    return math.abs(b) < math.abs(a) and b or a
end

function Utils.absMax(a, b)
    return math.abs(b) > math.abs(a) and b or a
end

function Utils.facingFromAngle(angle)
    local deg = math.deg(angle) % 360

    if deg >= 315 or deg <= 45 then
        return "right"
    elseif deg >= 45 and deg <= 135 then
        return "down"
    elseif deg >= 135 and deg <= 225 then
        return "left"
    elseif deg >= 225 and deg <= 315 then
        return "up"
    else
        return "right"
    end
end

function Utils.isFacingAngle(facing, angle)
    local deg = math.deg(angle) % 360

    if facing == "right" then
        return deg >= 315 or deg <= 45
    elseif facing == "down" then
        return deg >= 45 and deg <= 135
    elseif facing == "left" then
        return deg >= 135 and deg <= 225
    elseif facing == "up" then
        return deg >= 225 and deg <= 315
    end
    return false
end

function Utils.getFacingVector(facing)
    if facing == "right" then
        return 1, 0
    elseif facing == "down" then
        return 0, 1
    elseif facing == "left" then
        return -1, 0
    elseif facing == "up" then
        return 0, -1
    end
    return 0, 0
end

function Utils.stringInsert(str1, str2, pos)
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + 1)
end

function Utils.parsePropertyList(id, properties)
    properties = properties or {}
    if properties[id] then
        return {properties[id]}
    else
        local result = {}
        local i = 1
        while properties[id..i] do
            table.insert(result, properties[id..i])
            i = i + 1
        end
        return result
    end
end

function Utils.parsePropertyMultiList(id, properties)
    local single_list = Utils.parsePropertyList(id, properties)
    if #single_list > 0 then
        return {single_list}
    else
        local result = {}
        local i = 1
        while properties[id..i.."_1"] do
            local list = {}
            local j = 1
            while properties[id..i.."_"..j] do
                table.insert(list, properties[id..i.."_"..j])
                j = j + 1
            end
            table.insert(result, list)
            i = i + 1
        end
        return result
    end
end

function Utils.parseFlagProperties(flag, inverted, value, default_value, properties)
    properties = properties or {}
    local result_inverted = false
    local result_flag = nil
    local result_value = default_value
    if properties[flag] then
        result_inverted, result_flag = Utils.startsWith(properties[flag], "!")
    end
    if properties[inverted] then
        result_inverted = not result_inverted
    end
    if properties[value] then
        result_value = properties[value]
    end
    return result_flag, result_inverted, result_value
end

function Utils.getPointOnPath(path, t)
    local max_x, max_y = 0, 0
    local traversed = 0
    for i = 1, #path - 1 do
        local current_point = path[i]
        local next_point = path[i + 1]

        local cx, cy = current_point.x or current_point[1], current_point.y or current_point[2]
        local nx, ny = next_point.x or next_point[1], next_point.y or next_point[2]

        local current_length = Utils.dist(cx, cy, nx, ny)

        if traversed + current_length > t then
            local progress = (t - traversed) / current_length
            return Utils.lerp(cx, nx, progress), Utils.lerp(cy, ny, progress)
        end

        max_x, max_y = nx, ny

        traversed = traversed + current_length
    end
    return max_x, max_y
end

function Utils.format(str, tbl)
    local processed = {}
    for i,v in ipairs(tbl) do
        table.insert(processed, i)
        if str:gsub("{"..i.."}", v) ~= str then
            str = str:gsub("{"..i.."}", v)
        elseif str:gsub("{}", v, 1) ~= str then
            str = str:gsub("{}", tostring(v), 1)
        else
            error("Attempt to format string with no match")
        end
    end
    for k,v in pairs(tbl) do
        if not Utils.containsValue(processed, k) then -- ipairs already did this
            table.insert(processed, k) -- unneeded but just in case we need to expand this function later
            if str:gsub("{"..k.."}", v) ~= str then
                str = str:gsub("{"..k.."}", tostring(v))
            else
                error("Attempt to format string with no match for key \"" .. k .. "\"")
            end
        end
    end
    -- TODO: If there's still {} left, let's try to run its contents as code
    return str
end

function Utils.findFiles(folder, base, path)
    -- getDirectoryItems but recursive.
    -- The base argument is solely to remove stuff.
    -- The path is what we should append to the start of the file name.

    local base_folder = base or (folder .. "/")
    local path = path or ""
    local files = {}
    for _, f in ipairs(love.filesystem.getDirectoryItems(folder)) do
        local info = love.filesystem.getInfo(folder .. "/" .. f)
        if info.type == "directory" then
            table.insert(files, path .. (f:gsub(base_folder,"",1)))
            local new_path = path .. f .. "/"
            for _, ff in ipairs(Utils.findFiles(folder.."/"..f, base_folder, new_path)) do
                table.insert(files, (ff:gsub(base_folder,"",1)))
            end
        else
            table.insert(files, ((folder.."/"..f):gsub(base_folder,"",1)))
        end
    end
    return files
end

function Utils.parseTileGid(id)
    return bit.band(id, 268435455),
           bit.band(id, 2147483648) ~= 0,
           bit.band(id, 1073741824) ~= 0,
           bit.band(id, 536870912) ~= 0
end

function Utils.colliderFromShape(parent, data, x, y, properties)
    x, y = x or 0, y or 0
    properties = properties or {}

    local mode = {
        invert = properties["inverted"] or properties["outside"] or false,
        inside = properties["inside"] or properties["outside"] or false
    }

    local current_hitbox
    if data.shape == "rectangle" then
        current_hitbox = Hitbox(parent, x, y, data.width, data.height, mode)
    elseif data.shape == "polyline" then
        local line_colliders = {}
        for i = 1, #data.polyline-1 do
            local j = i + 1
            local x1, y1 = x + data.polyline[i].x, y + data.polyline[i].y
            local x2, y2 = x + data.polyline[j].x, y + data.polyline[j].y
            table.insert(line_colliders, LineCollider(parent, x1, y1, x2, y2, mode))
        end
        current_hitbox = ColliderGroup(parent, line_colliders)
    elseif data.shape == "polygon" then
        local points = {}
        for i = 1, #data.polygon do
            table.insert(points, {x + data.polygon[i].x, y + data.polygon[i].y})
        end
        current_hitbox = PolygonCollider(parent, points, mode)
    end

    if properties["enabled"] == false then
        current_hitbox.collidable = false
    end

    return current_hitbox
end

function Utils.padSpacing(str, len, beginning)
    for i = #str, (len - 1) do
        if beginning then
            str = " " .. str
        else
            str = str .. " "
        end
    end
    return str
end

return Utils