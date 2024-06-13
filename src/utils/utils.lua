local Utils = {}

---
--- Returns a substring of the specified string, properly accounting for UTF-8.
---
---@param s  string         # The initial string to get a substring of.
---@param i  number         # The index that the substring should start at.
---@param j? number         # The index that the substring should end at. (Defaults to -1, referring to the last character of the string)
---@return string substring # The new substring.
---
function Utils.sub(s,i,j)
    i = i or 1
    j = j or -1
    if i<1 or j<1 then
        local n = utf8.len(s)
        if not n then error("Invalid UTF-8 string.") end
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
    else return "" end
end

---
--- Returns whether every value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func? fun(v:T):boolean # If provided, each value of the table will instead be passed into the function, whose returned value will be considered instead of the table value itself.
---@return boolean result        # Whether every value was true or not.
---
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

---
--- Returns whether any individual value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func? fun(v:T):boolean # If provided, each value of the table will instead be passed into the function, whose returned value will be considered instead of the table value itself.
---@return boolean result        # Whether any value was true or not.
---
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

---
--- Makes a new copy of a table, giving it all of the same values.
---
---@generic T : table?
---@param tbl T          # The table to copy.
---@param deep? boolean  # Whether tables inside the specified table should be copied as well.
---@param seen? table    # *(Used internally)* A table of values used to keep track of which objects have been cloned.
---@return T new         # The new table.
---
function Utils.copy(tbl, deep, seen)
    if tbl == nil then return nil end
    local new_tbl = {}
    Utils.copyInto(new_tbl, tbl, deep, seen)
    return new_tbl
end

---
--- Copies the values of one table into a different one.
---
---@param new_tbl table # The table receiving the copied values.
---@param tbl table     # The table to copy values from.
---@param deep? boolean # Whether tables inside the specified table should be copied as well.
---@param seen? table   # *(Used internally)* A table of values used to keep track of which objects have been cloned.
---
function Utils.copyInto(new_tbl, tbl, deep, seen)
    if tbl == nil then return nil end

    -- Remember the current table we're copying, so we can avoid
    -- infinite loops when deep copying tables that reference themselves.
    seen = seen or {}
    seen[tbl] = new_tbl

    for k,v in pairs(tbl) do
        -- If we're deep copying, and the value is a table, then we need to copy that table as well.
        if type(v) == "table" and deep then
            if seen[v] then
                -- If we've already seen this table, use the same copy.
                new_tbl[k] = seen[v]
            elseif (not isClass(v) or (v.canDeepCopy and v:canDeepCopy())) and (not isClass(tbl) or (tbl:canDeepCopyKey(k) and not tbl.__dont_include[k])) then
                -- Unless the current value is a class that doesn't want to be deep copied,
                -- or the member of a class that doesn't want it to be deep copied, we can copy it.
                new_tbl[k] = {}
                Utils.copyInto(new_tbl[k], v, true, seen)
            else
                -- Otherwise, just copy the reference.
                new_tbl[k] = v
            end
        else
            -- The value isn't a table or we're not deep copying, so just use the value.
            new_tbl[k] = v
        end
    end

    -- Copy the metatable too.
    setmetatable(new_tbl, getmetatable(tbl))

    -- Call the onClone callback on the newly copied table, if it exists.
    if new_tbl.onClone then
        new_tbl:onClone(tbl)
    end
end

---
--- Empties a table of all defined values.
---
---@param tbl table # The table to clear.
---
function Utils.clear(tbl)
    for key in pairs(tbl) do
        tbl[key] = nil
    end
end

---
--- Returns the name of a given class, using the name of the global variable for the class. \
--- If it cannot find a global variable associated with the class, it will instead return the name of the class it extends, along with the class's ID.
---
---@param class table           # The class instance to check.
---@param parent_check? boolean # Whether the function should only return the extended class, and not attach the class's ID, if the class does not have a global name.
---@return string? name         # The name of the class, or `nil` if it cannot find one.
---
function Utils.getClassName(class, parent_check)
    -- If the class is a global variable, return its name.
    for k,v in pairs(_G) do
        if class.__index == v then
            return k
        end
    end
    -- If the class doesn't have a global variable, find the name of the highest class it extends.
    for i,v in ipairs(class.__includes) do
        local name = Utils.getClassName(v, true)
        if name then
            if not parent_check and class.id then
                -- If the class has an ID, append it to the name of its parent class.
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
    elseif type(key) == 'string' and (not key:find("[^%w_]") and not tonumber(key:sub(1,1)) and key ~= "") then
        return key
    else
        return '['..Utils.dump(key)..']'
    end
end

---
--- Returns a string converting a table value into readable text. Useful for debugging table values.
---
---@param o any          # The value to convert to a string.
---@return string result # The newly generated string.
---
function Utils.dump(o)
    if type(o) == 'table' then
        if isClass(o) then
            -- If the table is a class, return the
            -- name of the class instead of its contents.
            return Utils.getClassName(o) or "<unknown class>"
        end
        local s = '{'
        local cn = 1
        if Utils.isArray(o) then
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

---
--- Returns every numerically indexed value of a table. \
--- This fixes the issue with `unpack()` not returning `nil` values.
---
---@generic T
---@param t T[]  # The table to unpack.
---@return T ... # The values of the table.
---
function Utils.unpack(t)
    return unpack(t, 1, table.maxn(t))
end

---
--- Splits a string into a new table of strings using a single character as a separator. \
--- More optimized than `Utils.split()`, at the cost of lacking features. \
--- **Note**: This function uses `gmatch`, so special characters must be escaped with a `%`.
---
---@param str string       # The string to separate.
---@param sep string       # The character used to split the main string.
---@return string[] result # The table containing the new split strings.
---
function Utils.splitFast(str, sep)
    local t={} ; local i=1
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        t[i] = s
        i = i + 1
    end
    return t
end

---
--- Splits a string into a new table of strings using a substring as a separator. \
--- Less optimized than `Utils.splitFast()`, but allows separating with multiple characters, and is more likely to work for *any* string.
---
---@param str string            # The string to separate.
---@param sep string            # The substring used to split the main string.
---@param remove_empty? boolean # Whether strings containing no characters shouldn't be included in the result table.
---@return string[] result      # The table containing the new split strings.
---
function Utils.split(str, sep, remove_empty)
    local t = {}
    local i = 1
    local s = ""
    -- Loop through each character in the string.
    while i <= utf8.len(str) do
        -- If the current character matches the separator, add the
        -- current string to the table, and reset the current string.
        if Utils.sub(str, i, i + (utf8.len(sep) - 1)) == sep then
            -- If the string is empty, and empty strings shouldn't be included, skip it.
            if not remove_empty or s ~= "" then
                table.insert(t, s)
            end
            s = ""
            -- Skip the separator.
            i = i + (#sep - 1)
        else
            -- Add the character to the current string.
            s = s .. Utils.sub(str, i, i)
        end
        i = i + 1
    end
    -- Add the last string to the table.
    if not remove_empty or s ~= "" then
        table.insert(t, s)
    end
    return t
end

Utils.__MOD_HOOKS = {}
---
--- Replaces a function within a class with a new function. \
--- Also allows calling the original function, allowing you to add code to the beginning or end of existing functions. \
--- `Utils.hook()` should always be called in `Mod:init()`. An example of how to hook a function is as follows:
--- ```lua
--- -- this code will hook 'Object:setPosition(x, y)', and will be run whenever that function is called
--- -- all class functions receive the object instance as the first argument. in this function, i name that argument 'obj', and it refers to whichever object is calling 'setPosition()'
--- Utils.hook(Object, "setPosition", function(orig, obj, x, y)
---     -- calls the original code (setting its position as normal)
---     orig(obj, x, y)
---     
---     -- sets 'new_x' and 'new_y' variables for the object instance
---     obj.new_x = x
---     obj.new_y = y
--- end)
--- ```
---
---@param target table                 # The class variable containing the function you want to hook.
---@param name string                  # The name of the function to hook.
---@param hook fun(orig:fun(...), ...) # The function containing the new code to replace the old code with. Receives the original function as an argument, followed by the arguments the original function receives.
---@param exact_func? boolean          # *(Used internally)* Whether the function should be replaced exactly, or whether it should be replaced with a function that calls the hook function. Should not be specified by users.
---
function Utils.hook(target, name, hook, exact_func)
    -- Get the original function.
    local orig = target[name]

    -- If a mod is currently loaded, store information about the hook so it can be disabled later.
    if Mod then
        table.insert(Utils.__MOD_HOOKS, 1, {target = target, name = name, hook = hook, orig = orig})
    end

    local orig_func = orig or function() end
    if not exact_func then
        -- If the function should not be copied directly (such as when we're applying hooks to sub-classes),
        -- create a new function that calls the hook function, giving it the original function as an argument.
        target[name] = function(...)
            return hook(orig_func, ...)
        end
    else
        -- Otherwise, just replace the function with the hook function.
        target[name] = hook
    end

    -- If the target is a class, we need to apply the hook to all sub-classes
    -- that reference the original function.
    if isClass(target) then
        for _,includer in ipairs(target.__includers or {}) do
            if includer[name] == orig then
                Utils.hook(includer, name, target[name], true)
            end
        end
    end
end

---
--- Returns a function that calls a new function, giving it an older function as an argument. \
--- Essentially, it's a version of `Utils.hook()` that works with local functions.
---
---@generic T : function
---@param old_func T                # The function to be passed into the new function.
---@param new_func fun(orig:T, ...) # The new function that will be called by the result function.
---@return T result_func            # A function that will call the new function, providing the original function as an argument, followed by any other arguments that this function receives.
---
function Utils.override(old_func, new_func)
    old_func = old_func or function() end
    return function(...)
        return new_func(old_func, ...)
    end
end

---
--- Returns whether two tables have an equivalent set of values.
---
---@param a any            # The first table to compare.
---@param b any            # The second table to compare.
---@param deep? boolean    # Whether table values within these tables should also be compared using `Utils.equal()`.
---@return boolean success # Whether the sets of values for the two tables were equivalent.
---
function Utils.equal(a, b, deep)
    if type(a) ~= type(b) then
        -- Values are only equal if their types are the same
        return false
    elseif type(a) == "table" then
        -- Tables are equal if they have the same keys and values
        for k,v in pairs(a) do
            if b[k] == nil then
                return false
            -- If deep comparison is enabled, check `Utils.equal()` for the values
            elseif deep and not Utils.equal(v, b[k], true) then
                return false
            -- Otherwise, just check if the values are equal
            elseif not deep and v ~= b[k] then
                return false
            end
        end
        -- Check if the tables have the same number of keys
        for k,v in pairs(b) do
            if a[k] == nil then
                return false
            end
        end
    elseif a ~= b then
        -- Basic comparison if the values are not tables
        return false
    end
    -- No checks failed, so the values are equal
    return true
end

---
--- Returns a table of file names within the specified directory, checking subfolders as well.
---
---@param dir string       # The file path to check, relative to the LÖVE Kristal directory.
---@param ext? string      # If specified, only files with the specified extension will be returned, and the extension will be stripped. (eg. `"png"` will only return .png files)
---@return string[] result # The table of file names.
---
function Utils.getFilesRecursive(dir, ext)
    local result = {}

    -- Get all files and folders within the specified directory
    local paths = love.filesystem.getDirectoryItems(dir)
    for _,path in ipairs(paths) do
        local info = love.filesystem.getInfo(dir.."/"..path)

        if info.type == "directory" then
            -- If the path is a folder, recursively get all files within that folder
            local inners = Utils.getFilesRecursive(dir.."/"..path, ext)
            for _,inner in ipairs(inners) do
                -- Append the current folder path to files from the subfolder
                table.insert(result, path.."/"..inner)
            end
        elseif not ext or path:sub(-#ext) == ext then
            -- If the path is a file, add it to the result table.
            -- If an extension is specified, only add files with that extension,
            -- and remove the extension from the file name.
            table.insert(result, ext and path:sub(1, -#ext-1) or path)
        end
    end

    return result
end

---
--- Concatenates exclusively string values within a table.
---
---@param text table|string # The table of values to combine.
---@return string result    # The concatenated string.
---
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

---
--- Converts HSL values to RGB values. Both HSL and RGB should be values between 0 and 1.
---
---@param h number  # The hue value of the HSL color.
---@param s number  # The saturation value of the HSL color.
---@param l number  # The lightness value of the HSL color.
---@return number r # The red value of the converted color.
---@return number g # The green value of the converted color.
---@return number b # The blue value of the converted color.
---
--- *Source*: https://github.com/Wavalab/rgb-hsl-rgb
---
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

---
--- Converts RGB values to HSL values. Both RGB and HSL should be values between 0 and 1.
---
---@param r number  # The red value of the RGB color.
---@param g number  # The green value of the RGB color.
---@param b number  # The blue value of the RGB color.
---@return number h # The hue value of the converted color.
---@return number s # The saturation value of the converted color.
---@return number l # The lightness value of the converted color.
---
--- *Source*: https://github.com/Wavalab/rgb-hsl-rgb
---
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

---
--- Converts HSV values to RGB values. Both HSV and RGB should be values between 0 and 1.
---
---@param h number  # The hue value of the HSV color.
---@param s number  # The saturation value of the HSV color.
---@param v number  # The 'value' value of the HSV color.
---@return number r # The red value of the converted color.
---@return number g # The green value of the converted color.
---@return number b # The blue value of the converted color.
---
--- *Source*: https://love2d.org/wiki/HSV_color
---
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

---
--- Converts a hex color string to an RGBA color table.
---
---@param hex string     # The string to convert to RGB. The string *must* be formatted with a # at the start, eg. `"#ff00ff"`.
---@param value? number  # An optional number specifying the alpha the returned table should have.
---@return number[] rgba # The converted RGBA table.
---
--- *Source*: https://github.com/s-walrus/hex2color
---
function Utils.hexToRgb(hex, value)
    return {tonumber(string.sub(hex, 2, 3), 16)/256, tonumber(string.sub(hex, 4, 5), 16)/256, tonumber(string.sub(hex, 6, 7), 16)/256, value or 1}
end

---
--- Converts a table of RGB values to a hex color string.
---
---@param rgb number[] # The RGB table to convert. Values should be between 0 and 1.
---@return string hex  # The converted hex string. Formatted with a # at the start, eg. "#ff00ff".
---
function Utils.rgbToHex(rgb)
    return string.format("#%02X%02X%02X", rgb[1]*255, rgb[2]*255, rgb[3]*255)
end

---
--- Converts a Tiled color property to an RGBA color table.
---
---@param property string # The property string to convert.
---@return number[]? rgba # The converted RGBA table.
---
function Utils.parseColorProperty(property)
    if not property then return nil end
    -- Tiled color properties are formatted as #AARRGGBB, where AA is the alpha value.
    local str = "#"..string.sub(property, 4) -- Get the hex string without the alpha value
    local a = tonumber(string.sub(property, 2, 3), 16)/256 -- Get the alpha value separately
    return Utils.hexToRgb(str, a)
end

---
--- Merges the values of one table into another one.
---
---@param tbl table     # The table to merge values into.
---@param other table   # The table to copy values from.
---@param deep? boolean # Whether shared table values between the two tables should also be merged.
---@return table tbl    # The initial table, now containing new values.
---
function Utils.merge(tbl, other, deep)
    if Utils.isArray(other) then
        -- If the source table is an array, just append the values
        -- to the end of the destination table.
        for _,v in ipairs(other) do
            table.insert(tbl, v)
        end
    else
        for k,v in pairs(other) do
            if deep and type(tbl[k]) == "table" and type(v) == "table" then
                -- If we're deep merging and both values are tables,
                -- merge the tables together.
                Utils.merge(tbl[k], v, true)
            else
                -- Otherwise, just copy the value over.
                tbl[k] = v
            end
        end
    end
    return tbl
end

---
--- Merges a list of tables into a new table.
---
---@param ... table     # The list of tables to merge values from.
---@return table result # A new table containing the values of the series of tables provided.
---
function Utils.mergeMultiple(...)
    local tbl = {}
    for _,other in ipairs{...} do
        Utils.merge(tbl, other)
    end
    return tbl
end

---
--- Returns whether a table contains exclusively numerical indexes.
---
---@param tbl table       # The table to check.
---@return boolean result # Whether the table contains only numerical indexes or not.
---
function Utils.isArray(tbl)
    for k,_ in pairs(tbl) do
        if type(k) ~= "number" then
            return false
        end
    end
    return true
end

---
--- Removes the specified value from the table.
---
---@generic T
---@param tbl table # The table to remove the value from.
---@param val T     # The value to be removed from the table.
---@return T? val   # The now removed value.
---
function Utils.removeFromTable(tbl, val)
    for i,v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return v
        end
    end
end

---
--- Whether the table contains the specified value.
---
---@param tbl table       # The table to check the value from.
---@param val any         # The value to check.
---@return boolean result # Whether the table contains the specified value.
---
function Utils.containsValue(tbl, val)
    for k,v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

---
--- Rotates the values of a 2-dimensional array. \
--- As an example, the following table:
--- ```lua
--- {
---     {1, 2},
---     {3, 4},
--- }
--- ```
--- would result in this when passed into the function, rotating it clockwise:
--- ```lua
--- {
---     {3, 1},
---     {4, 2},
--- }
--- ```
---
---@param tbl table     # The table array to rotate the values of.
---@param ccw? boolean  # Whether the rotation should be counterclockwise.
---@return table result # The new rotated array.
---
function Utils.rotateTable(tbl, ccw)
    local result = {}
    local max = 0
    for _,v in ipairs(tbl) do
        if type(v) ~= "table" then
            error("table contains non-table value: "..v)
        else
            max = math.max(max, #v)
        end
    end
    for i=1,max do
        result[i] = {}
        for j=1,#tbl do
            if ccw then
                result[i][j] = tbl[j][(max+1)-i]
            else
                result[i][j] = tbl[(#tbl+1)-j][i]
            end
        end
    end
    return result
end

---
--- Flips the values of a 2-dimensional array, such that its columns become its rows, and vice versa. \
--- As an example, the following table:
--- ```lua
--- {
---     {1, 2},
---     {3, 4},
--- }
--- ```
--- would result in this when passed into the function:
--- ```lua
--- {
---     {1, 3},
---     {2, 4},
--- }
--- ```
---
---@param tbl table     # The table array to flip the values of.
---@return table result # The new flipped array.
---
function Utils.flipTable(tbl)
    local result = {}
    local max = 0
    for _,v in ipairs(tbl) do
        if type(v) ~= "table" then
            error("table contains non-table value: "..v)
        else
            max = math.max(max, #v)
        end
    end
    for i=1,max do
        result[i] = {}
        for j=1,#tbl do
            result[i][j] = tbl[j][i]
        end
    end
    return result
end

---
--- Rounds the specified value down to the nearest integer.
---
---@param value number   # The value to round.
---@param to? number     # If specified, the value will instead be rounded down to the nearest multiple of this number.
---@return number result # The rounded value.
---
function Utils.floor(value, to)
    if not to then
        return math.floor(value)
    elseif to == 0 then
        return 0
    else
        return math.floor(value/to)*to
    end
end

---
--- Rounds the specified value up to the nearest integer.
---
---@param value number   # The value to round.
---@param to? number     # If specified, the value will instead be rounded up to the nearest multiple of this number.
---@return number result # The rounded value.
---
function Utils.ceil(value, to)
    if not to then
        return math.ceil(value)
    elseif to == 0 then
        return 0
    else
        return math.ceil(value/to)*to
    end
end

---
--- Rounds the specified value to the nearest integer.
---
---@param value number   # The value to round.
---@param to? number     # If specified, the value will instead be rounded to the nearest multiple of this number.
---@return number result # The rounded value.
---
function Utils.round(value, to)
    if not to then
        return math.floor(value + 0.5)
    else
        return math.floor((value + (to/2)) / to) * to
    end
end

---
--- Rounds the specified value to the nearest integer towards zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
function Utils.roundToZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.floor(value) end
    if value < 0 then return math.ceil(value) end
    return 0/0 -- return NaN lol
end

---
--- Rounds the specified value to the nearest integer away from zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
function Utils.roundFromZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.ceil(value) end
    if value < 0 then return math.floor(value) end
    return 0/0 -- return NaN lol
end

---
--- Returns whether two numbers are roughly equal (less than 0.01 away from each other).
---
---@param a number        # The first value to compare.
---@param b number        # The second value to compare.
---@return boolean result # Whether the two values are roughly equal.
---
function Utils.roughEqual(a, b)
    return math.abs(a - b) < 0.01
end

---
--- Limits the specified value to be between 2 bounds, setting it to be the respective bound if it exceeds it.
---
---@param val number     # The value to limit.
---@param min number     # The minimum bound. If the value is less than this number, it is set to it.
---@param max number     # The maximum bound. If the value is greater than this number, it is set to it.
---@return number result # The new limited number.
---
function Utils.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

---
--- Returns the polarity of the specified value: -1 if it's negative, 1 if it's positive, and 0 otherwise.
---
---@param num number   # The value to check.
---@return number sign # The sign of the value.
---
function Utils.sign(num)
    return num > 0 and 1 or (num < 0 and -1 or 0)
end

---
--- Moves the specified value towards a target value by a specified amount, without exceeding the target. \
--- If the target is less than the value, then the amount will be subtracted from the value instead to approach it.
---
---@param val number     # The initial value.
---@param target number  # The target value to approach.
---@param amount number  # The amount the initial value should approach the target by.
---@return number result # The new value. If the value would have passed the target value, it will instead be set to the target.
---
function Utils.approach(val, target, amount)
    if target < val then
        return math.max(target, val - amount)
    elseif target > val then
        return math.min(target, val + amount)
    end
    return target
end

---
--- Moves the specified angle towards a target angle by a specified amount, properly accounting for wrapping around. \
--- Will always approach in the direction with the shorter distance.
---
---@param val number     # The initial angle.
---@param target number  # The target angle to approach.
---@param amount number  # The amount the initial angle should approach the target by.
---@return number result # The new angle. If the angle would have passed the target angle, it will instead be set to the target.
---
function Utils.approachAngle(val, target, amount)
    local to = val + Utils.angleDiff(target, val)
    return Utils.approach(val, to, amount)
end

---
--- Returns a value between two numbers, determined by a percentage from 0 to 1. \
--- If given a table, it will lerp between each value in the table.
---
---@generic T : number|table
---@param a T          # The start value of the range.
---@param b T          # The end value of the range.
---@param t number     # The percentage (from 0 to 1) that determines the point on the specified range.
---@param oob? boolean # If true, then the percentage can be values beyond the range of 0 to 1.
---@return T result    # The new value from the range.
---
function Utils.lerp(a, b, t, oob)
    if type(a) == "table" and type(b) == "table" then
        local o = {}
        for k,v in ipairs(a) do
            table.insert(o, Utils.lerp(v, b[k] or v, t, oob))
        end
        return o
    else
        return a + (b - a) * (oob and t or Utils.clamp(t, 0, 1))
    end
end

---
--- Lerps between two coordinates.
---
---@param x1 number     # The horizontal position of the first point.
---@param y1 number     # The vertical position of the first point.
---@param x2 number     # The horizontal position of the second point.
---@param y2 number     # The vertical position of the second point.
---@param t number      # The percentage (from 0 to 1) that determines the new point on the specified range between the specified points.
---@param oob? boolean  # If true, then the percentage can be values beyond the range of 0 to 1.
---@return number new_x # The horizontal position of the new point.
---@return number new_y # The vertical position of the new point.
---
function Utils.lerpPoint(x1, y1, x2, y2, t, oob)
    return Utils.lerp(x1, x2, t, oob), Utils.lerp(y1, y2, t, oob)
end

---@alias easetype
---| "linear"
---| "in-quad"
---| "in-cubic"
---| "in-quart"
---| "in-quint"
---| "in-sine"
---| "in-expo"
---| "in-circ"
---| "in-back"
---| "in-bounce"
---| "in-elastic"
---| "out-quad"
---| "out-cubic"
---| "out-quart"
---| "out-quint"
---| "out-sine"
---| "out-expo"
---| "out-circ"
---| "out-back"
---| "out-bounce"
---| "out-elastic"
---| "in-out-quad"
---| "in-out-cubic"
---| "in-out-quart"
---| "in-out-quint"
---| "in-out-sine"
---| "in-out-expo"
---| "in-out-circ"
---| "in-out-back"
---| "in-out-bounce"
---| "in-out-elastic"
---| "inQuad"
---| "outQuad"
---| "inOutQuad"
---| "outInQuad"
---| "inCubic"
---| "outCubic"
---| "inOutCubic"
---| "outInCubic"
---| "inQuart"
---| "outQuart"
---| "inOutQuart"
---| "outInQuart"
---| "inQuint"
---| "outQuint"
---| "inOutQuint"
---| "outInQuint"
---| "inSine"
---| "outSine"
---| "inOutSine"
---| "outInSine"
---| "inExpo"
---| "outExpo"
---| "inOutExpo"
---| "outInExpo"
---| "inCirc"
---| "outCirc"
---| "inOutCirc"
---| "outInCirc"
---| "inElastic"
---| "outElastic"
---| "inOutElastic"
---| "outInElastic"
---| "inBack"
---| "outBack"
---| "inOutBack"
---| "outInBack"
---| "inBounce"
---| "outBounce"
---| "inOutBounce"
---| "outInBounce"

---
--- Returns a value eased between two numbers, determined by a percentage from 0 to 1.
---
---@param a number      # The start value of the range.
---@param b number      # The end value of the range.
---@param t number      # The percentage (from 0 to 1) that determines the point on the specified range.
---@param mode easetype # The ease type to use between the two values. (Refer to https://easings.net/)
---
function Utils.ease(a, b, t, mode)
    if t >= 1 then
        return b
    else
        if not Ease[mode] then
            error("\""..tostring(mode).."\" is not a valid easing method")
        end
        return Ease[mode](Utils.clamp(t, 0, 1), a, (b - a), 1)
    end
end

---
--- Maps a value between a specified range to its equivalent position in a new range.
---
---@param val number     # The initial value in the initial range.
---@param min_a number   # The start value of the initial range.
---@param max_a number   # The end value of the initial range.
---@param min_b number   # The start value of the new range.
---@param max_b number   # The end value of the new range.
---@param mode? easetype # If specified, the value's new position will be eased into the new range based on the percentage of its position in its initial range.
---@return number result # The value within the new range.
---
function Utils.clampMap(val, min_a, max_a, min_b, max_b, mode)
    if min_a > max_a then
        -- Swap min and max
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

---
--- Returns a value between two numbers, sinusoidally positioned based on the specified value.
---
---@param val number     # The number used to determine the sine position.
---@param min number     # The start value of the range.
---@param max number     # The end value of the range.
---@return number result # The sine-based value within the range.
---
function Utils.wave(val, min, max)
    return Utils.clampMap(math.sin(val), -1,1, min or -1,max or 1)
end

---
--- Returns whether a value is between two numbers.
---
---@param val number       # The value to compare.
---@param a number         # The start value of the range.
---@param b number         # The end value of the range.
---@param include? boolean # Determines whether the function should consider being equal to a range value to be "between". (Defaults to false)
---@return boolean result  # Whether the value was within the range.
---
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
            Kristal.Console:log("["..PERFORMANCE_TEST_STAGE.."] "..k.. " | "..#times.." calls | "..(n / #times).." | Total: "..n)
        end
    end
    if PERFORMANCE_TEST["Total"] then
        Kristal.Console:log("["..PERFORMANCE_TEST_STAGE.."] Total: "..PERFORMANCE_TEST["Total"][1])
    end
end

---
--- Merges two colors based on a percentage between 0 and 1.
---
---@param start_color number[]   # The first table of RGBA values to merge.
---@param end_color number[]     # The second table of RGBA values to merge.
---@param amount number          # A percentage (from 0 to 1) that determines how much of the second color to merge into the first.
---@return number[] result_color # A new table of RGBA values.
---
function Utils.mergeColor(start_color, end_color, amount)
    local color = {
        Utils.lerp(start_color[1],      end_color[1],      amount),
        Utils.lerp(start_color[2],      end_color[2],      amount),
        Utils.lerp(start_color[3],      end_color[3],      amount),
        Utils.lerp(start_color[4] or 1, end_color[4] or 1, amount)
    }
    return color
end

---@alias point number[]
---@alias edge {[1]:point, [2]:point, ["angle"]:number}

---
--- Returns a table of line segments based on a set of polygon points.
---
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return edge[] edges  # An array of tables containing four values each, defining line segments describing the edges of a polygon.
---
function Utils.getPolygonEdges(points)
    local edges = {}
    for i = 1, #points do
        local p1, p2 = points[i], points[(i % #points) + 1]
        table.insert(edges, {p1, p2, angle=math.atan2(p2[2] - p1[2], p2[1] - p1[1])})
    end
    return edges
end

---
--- Determines whether a polygon's points are clockwise or counterclockwise.
---
---@param points point[]  # An array of tables with two number values each, defining the points of a polygon.
---@return boolean result # Whether the polygon is clockwise or not.
---
function Utils.isPolygonClockwise(points)
    local edges = Utils.getPolygonEdges(points)
    local sum = 0
    for _,edge in ipairs(edges) do
        sum = sum + ((edge[2][1] - edge[1][1]) * (edge[2][2] + edge[1][2]))
    end
    return sum > 0
end

--- @alias linefailure
---| "The lines are parallel."
---| "The lines don't intersect."

-- TODO: Language server will complain about the second return value here

---
--- Returns the point at which two lines intersect.
---
---@param l1p1x number          # The horizontal position of the first point for the first line.
---@param l1p1y number          # The vertical position of the first point for the first line.
---@param l1p2x number          # The horizontal position of the second point for the first line.
---@param l1p2y number          # The vertical position of the second point for the first line.
---@param l2p1x number          # The horizontal position of the first point for the second line.
---@param l2p1y number          # The vertical position of the first point for the second line.
---@param l2p2x number          # The horizontal position of the second point for the second line.
---@param l2p2y number          # The vertical position of the second point for the second line.
---@param seg1? boolean         # If true, the first line will be treated as a line segment instead of an infinite line.
---@param seg2? boolean         # If true, the second line will be treated as a line segment instead of an infinite line.
---@return number|boolean x     # If the lines intersected, this will be the horizontal position of the intersection; otherwise, this value will be `false`.
---@return number|linefailure y # If the lines intersected, this will be the vertical position of the intersection; otherwise, this will be a string describing why the lines did not intersect.
---
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

---
--- Returns a new polygon with points offset outwards by a certain distance.
---
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@param dist number    # The distance to offset the points by. If this value is negative, the points will be offset inwards.
---@return point[] A     # new polygon array.
---
function Utils.getPolygonOffset(points, dist)
    -- Get the sign of the polygon's winding direction
    local sign = Utils.isPolygonClockwise(points) and 1 or -1

    local function offsetPoint(x, y, angle, dist)
        return x + math.cos(angle) * dist, y + math.sin(angle) * dist
    end

    -- Loop through all the edges of the polygon
    local edges = Utils.getPolygonEdges(points)
    local new_polygon = {}
    for i = 1, #edges do
        -- Get the current and the next edge, wrapping around
        -- to the first edge if we're at the last one
        local e1, e2 = edges[i], edges[(i % #edges) + 1]

        -- Offset the points of the edges by the given distance
        local p1x, p1y = offsetPoint(e1[1][1], e1[1][2], e1.angle + sign * (math.pi/2), dist)
        local p2x, p2y = offsetPoint(e1[2][1], e1[2][2], e1.angle + sign * (math.pi/2), dist)
        local p3x, p3y = offsetPoint(e2[1][1], e2[1][2], e2.angle + sign * (math.pi/2), dist)
        local p4x, p4y = offsetPoint(e2[2][1], e2[2][2], e2.angle + sign * (math.pi/2), dist)

        -- Add the intersection point of the two offset edges to the new polygon
        local ix, iy = Utils.getLineIntersect(p1x,p1y, p2x,p2y, p3x,p3y, p4x,p4y)
        if ix then
            table.insert(new_polygon, {ix, iy})
        end
    end

    -- Move the last point to the start of the table
    table.insert(new_polygon, 1, table.remove(new_polygon, #new_polygon))

    return new_polygon
end

---
--- Converts a set of polygon points to a series of numbers.
---
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return number ...    # A series of numbers describing the horizontal and vertical positions of each point in the polygon.
---
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

--- Returns the bounds of a rectangle containing every point of a polygon.
---
---@param points point[] # An array of tables with two number values each, defining the points of a polygon.
---@return number x      # The horizontal position of the bounds.
---@return number y      # The vertical position of the bounds.
---@return number width  # The width of the bounds.
---@return number height # The height of the bounds.
---
function Utils.getPolygonBounds(points)
    local min_x, min_y, max_x, max_y
    for _,point in ipairs(points) do
        min_x, min_y = math.min(min_x or point[1], point[1]), math.min(min_y or point[2], point[2])
        max_x, max_y = math.max(max_x or point[1], point[1]), math.max(max_y or point[2], point[2])
    end
    return min_x, min_y, (max_x - min_x), (max_y - min_y)
end

---
--- Returns the values of an RGB table individually.
---
---@param color number[] # An RGB(A) table.
---@return number r      # The red value of the color.
---@return number g      # The green value of the color.
---@return number b      # The blue value of the color.
---@return number a      # The alpha value of the color, or 1 if it was not specified.
---
function Utils.unpackColor(color)
    return color[1], color[2], color[3], color[4] or 1
end

---
--- Returns a randomly generated decimal value. \
--- If no arguments are provided, the value is between 0 and 1. \
--- If `a` is provided, the value is between 0 and `a`. \
--- If `a` and `b` are provided, the value is between `a` and `b`. \
--- If `c` is provided, the value is between `a` and `b`, rounded to the nearest multiple of `c`.
---
---@param a? number   # The first argument.
---@param b? number   # The second argument.
---@param c? number   # The third argument.
---@return number rng # The new random value.
---
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

---
--- Returns either -1 or 1.
---
---@return number sign # The new random sign.
---
function Utils.randomSign()
    return love.math.random() < 0.5 and 1 or -1
end

---
--- Returns a table of 2 numbers, defining a vector in a random cardinal direction. (eg. `{0, -1}`)
---
---@return number[] vector # The vector table.
---
function Utils.randomAxis()
    local t = {Utils.randomSign()}
    table.insert(t, love.math.random(2), 0)
    return t
end

---
--- Returns the coordinates a random point along the border of the specified rectangle.
---
---@param x number  # The horizontal position of the topleft of the rectangle.
---@param y number  # The vertical position of the topleft of the rectangle.
---@param w number  # The width of the rectangle.
---@param h number  # The height of the rectangle.
---@return number x # The horizontal position of a random point on the rectangle border.
---@return number y # The vertical position of a random point on the rectangle border.
---
function Utils.randomPointOnBorder(x, y, w, h)
    if love.math.random() < 0.5 then
        local sx = (love.math.random() < 0.5) and x or x+w
        local sy = love.math.random(y, y+h)
        return sx, sy
    else
        local sx = love.math.random(x, x+w)
        local sy = (love.math.random() < 0.5) and y or y+h
        return sx, sy
    end
end

---
--- Returns a new table containing only values that a function returns true for.
---
---@generic T
---@param tbl T[]                 # An array of values.
---@param filter fun(v:T):boolean # A function that should return `true` for all values in the table to keep, and `false` for values to discard.
---@return T[] result             # A new array containing only approved values.
---
function Utils.filter(tbl, filter)
    local t = {}
    for _,v in ipairs(tbl) do
        if filter(v) then
            table.insert(t, v)
        end
    end
    return t
end

---
--- Removes values from a table if a function does not return true for them.
---
---@generic T
---@param tbl T[]                 # An array of values.
---@param filter fun(v:T):boolean # A function that should return `true` for all values in the table to keep, and `false` for values to discard.
---
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

---
--- Returns a random value from an array.
---
---@generic T
---@param tbl T[]                # An array of values.
---@param sort? fun(v:T):boolean # If specified, the table will be sorted via `Utils.filter(tbl, sort)` before selecting a value.
---@param remove? boolean        # If true, the selected value will be removed from the given table.
---@return T result              # The randomly selected value.
---
function Utils.pick(tbl, sort, remove)
    if sort then
        local indexes = {}
        for i,v in ipairs(tbl) do
            if sort(v) then
                table.insert(indexes, i)
            end
        end
        local i = indexes[love.math.random(#indexes)]
        if remove then
            return table.remove(tbl, i)
        else
            return tbl[i]
        end
    else
        if remove then
            return table.remove(tbl, love.math.random(#tbl))
        else
            return tbl[love.math.random(#tbl)]
        end
    end
end

---
--- Returns multiple random values from an array, not selecting any value more than once.
---
---@generic T
---@param tbl T[]                # An array of values.
---@param amount number          # The amount of values to select from the table.
---@param sort? fun(v:T):boolean # If specified, the table will be sorted via `Utils.filter(tbl, sort)` before selecting a value.
---@return T result              # A table containing the randomly selected values.
---
function Utils.pickMultiple(tbl, amount, sort, remove)
    local t = {}
    local indexes = {}
    for i,v in ipairs(tbl) do
        if not sort or sort(v) then
            table.insert(indexes, i)
        end
    end
    for _=1,amount do
        local i = table.remove(indexes, love.math.random(#indexes))
        if remove then
            table.insert(t, table.remove(tbl, i))
        else
            table.insert(t, tbl[i])
        end
    end
    return t
end

---
--- Returns a table containing the values of another table, randomly rearranged.
---
---@generic T
---@param tbl T[]     # An array of values.
---@return T[] result # The new randomly shuffled array.
---
function Utils.shuffle(tbl)
    return Utils.pickMultiple(tbl, #tbl)
end

---
--- Returns a table containing the values of an array in reverse order.
---
---@generic T
---@param tbl T[]       # An array of values.
---@param group? number # If defined, the values will be grouped into sets of the specified size, and those sets will be reversed.
---@return T[] result   # The new table containing the values of the specified array.
---
function Utils.reverse(tbl, group)
    local t = {}
    -- If a group is defined, split the table into groups of that size.
    if group then
        tbl = Utils.group(tbl, group)
    end
    -- Loop through the table backwards, and insert each value into the new table.
    for i=#tbl,1,-1 do
        table.insert(t, tbl[i])
    end
    -- If the table was grouped, flatten it back into a single array.
    if group then
        t = Utils.flatten(t)
    end
    return t
end

---
--- Merges a list of tables containing values into a single table containing each table's contents.
---
---@generic T
---@param tbl T[][]     # The array of tables to merge.
---@param deep? boolean # If true, tables contained inside listed tables will also be merged.
---@return T[] result   # The new table containing all values.
---
function Utils.flatten(tbl, deep)
    local t = {}
    for _,o in ipairs(tbl) do
        if type(o) == "table" and not isClass(o) then -- Do not flatten classes
            for _,v in ipairs(deep and Utils.flatten(o, true) or o) do
                table.insert(t, v)
            end
        else
            table.insert(t, o)
        end
    end
    return t
end

---
--- Creates a table grouping values of a table into a series of tables.
---
---@generic T
---@param tbl T[]       # The table to group values from.
---@param count number  # The amount of values that should belong in each group. If the table does not divide evenly, the final group of the returned table will be incomplete.
---@return T[][] result # The table containing the grouped values.
---
function Utils.group(tbl, count)
    local t = {}
    local i = 0
    while i <= #tbl do
        local o = {}
        for _=1,count do
            i = i + 1
            if tbl[i] then
                table.insert(o, tbl[i])
            else break end
        end
        if #o > 0 then
            table.insert(t, o)
        end
    end
    return t
end

---
--- Returns the angle from one point to another, or from one object's position to another's.
---
---@param x1 number|Object  # The horizontal position of the first point.
---@param y1 number|Object  # The vertical position of the first point.
---@param x2 number|Object  # The horizontal position of the second point.
---@param y2 number|Object  # The vertical position of the second point.
---@return number angle     # The angle from the first point to the second point.
---
---@overload fun(obj1:Object, obj2:Object): angle:number
---
function Utils.angle(x1,y1, x2,y2)
    if isClass(x1) and isClass(y1) and x1:includes(Object) and y1:includes(Object) then
        -- If two objects are passed, use their positions instead
        local obj1, obj2 = x1, y1
        if obj1.parent == obj2.parent then
            -- If the objects are in the same parent, use their local positions
            return math.atan2(obj2.y - obj1.y, obj2.x - obj1.x)
        else
            -- Otherwise, compare their screen positions
            local ox1, oy1 = obj1:getScreenPos()
            local ox2, oy2 = obj2:getScreenPos()
            return math.atan2(oy2 - oy1, ox2 - ox1)
        end
    else
        return math.atan2(y2 - y1, x2 - x1)
    end
end

---
--- Returns the distance between two angles, properly accounting for wrapping around.
---
---@param a number     # The first angle to compare.
---@param b number     # The second angle to compare.
---@return number diff # The difference between the two angles.
---
function Utils.angleDiff(a, b)
    local r = a - b
    return (r + math.pi) % (math.pi*2) - math.pi
end

---
--- Returns the distance between two points.
---
---@param x1 number    # The horizontal position of the first point.
---@param y1 number    # The vertical position of the first point.
---@param x2 number    # The horizontal position of the second point.
---@param y2 number    # The vertical position of the second point.
---@return number dist # The linear distance from the first point to the second point.
---
function Utils.dist(x1,y1, x2,y2)
    local dx, dy = x1-x2, y1-y2
    return math.sqrt(dx*dx + dy*dy)
end

---
--- Returns whether a string contains a given substring. \
--- **Note**: This function uses `find`, so special characters must be escaped with a `%`.
---
---@param str string      # The string to check.
---@param filter string   # The substring that the string may contain.
---@return boolean result # Whether the string contained the specified substring.
---
function Utils.contains(str, filter)
    return string.find(str, filter) ~= nil
end

---
--- Returns whether a string starts with the specified substring, or a table starts with the specified series of values. \
--- The function will also return a second value, created by copying the inital value and removing the prefix.
---
---@generic T : string|table
---@param value T          # The value to check the beginning of.
---@param prefix T         # The prefix that should be checked.
---@return boolean success # Whether the value started with the specified prefix.
---@return T rest          # A new value created by removing the prefix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function Utils.startsWith(value, prefix)
    if type(value) == "string" then
        -- If the value is a string, check if it starts with the prefix
        if value:sub(1, #prefix) == prefix then
            return true, value:sub(#prefix + 1)
        else
            return false, value
        end
    elseif type(value) == "table" then
        -- If the value is a table, check if the first few values match the prefix
        if #value < #prefix then
            -- Prefix cannot be longer than the value
            return false, value
        end
        -- Create a copy of the value to remove the prefix from
        local copy = Utils.copy(value)
        for i,v in ipairs(prefix) do
            if value[i] ~= v then
                -- Return false if any value in the prefix does not match
                return false, value
            end
            table.remove(copy, 1)
        end
        return true, copy
    end
    return false, value
end

---
--- Returns whether a string ends with the specified substring, or a table ends with the specified series of values. \
--- The function will also return a second value, created by copying the inital value and removing the suffix.
---
---@generic T : string|table
---@param value T          # The value to check the end of.
---@param suffix T         # The prefix that should be checked.
---@return boolean success # Whether the value ended with the specified suffix.
---@return T rest          # A new value created by removing the suffix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function Utils.endsWith(value, suffix)
    if type(value) == "string" then
        -- If the value is a string, check if it ends with the prefix
        if value:sub(-#suffix) == suffix then
            return true, value:sub(1, -#suffix - 1)
        else
            return false, value
        end
    elseif type(value) == "table" then
        -- If the value is a table, check if the last few values match the suffix
        if #value < #suffix then
            -- Suffix cannot be longer than the value
            return false, value
        end
        -- Create a copy of the value to remove the suffix from
        local copy = Utils.copy(value)
        for i = #value, 1, -1 do
            if suffix[#suffix + (i - #value)] ~= copy[i] then
                -- Return false if any value in the suffix does not match
                return false, value
            end
            table.remove(copy, i)
        end
        return true, copy
    end
    return false, value
end

-- TODO: this function is a mess please comment it later
---@param prefix string base directory of images in the mod
---@param image string raw image path specified by tileset/map
---@param path string path of tileset/map, `image` is relative to this
---@return string|nil final_path nil in case of error
function Utils.absoluteToLocalPath(prefix, image, path)
    prefix = Mod.info.path .. "/" .. prefix

    -- Split paths by seperator
    local base_path = Utils.split(path, "/")
    local dest_path = Utils.split(image, "/")
    while dest_path[1] == ".." do
        -- Move up one directory
        table.remove(base_path, #base_path)
        table.remove(dest_path, 1)
    end

    local final_path = table.concat(Utils.merge(base_path, dest_path), "/")

    -- Strip prefix
    local has_prefix
    has_prefix, final_path = Utils.startsWith(final_path, prefix)
    --print(prefix, final_path, has_prefix)
    if not has_prefix then return nil end

    -- Strip extension
    return final_path:sub(1, -1 - (final_path:reverse():find("%.") or 0))
end

---
--- Converts a string into a new string where the first letter of each "word" (determined by spaces between characters) will be capitalized.
---
---@param str string     # The initial string to edit.
---@return string result # The new string, in Title Case.
---
function Utils.titleCase(str)
    local buf = {}
    -- FIXME:
    ---@diagnostic disable-next-line: undefined-field
    for word in string.gfind(str, "%S+") do
        local first, rest = string.sub(word, 1, 1), string.sub(word, 2)
        table.insert(buf, string.upper(first) .. string.lower(rest))
    end
    return table.concat(buf, " ")
end

---
--- Returns how many indexes a table has, including non-numerical indexes.
---
---@param t table        # The table to check.
---@return number result # The amount of indexes found.
---
function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

---
--- Returns a non-numerical index based on its position in a `pairs()` iterator.
---
---@param t table        # The table to get the index from.
---@param number number  # The numerical position the index will be at.
---@return number? index # The index found at the specified position.
---
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

---
--- Returns a number based on the position of a specified key in a `pairs()` iterator.
---
---@param t table           # The table to get the position from.
---@param name any          # The key to find the position of.
---@return number? position # The numerical position of the specified index.
---
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

---
--- Returns the position of a specified value found within an array.
---
---@generic T
---@param t T[]             # The array to get the position from.
---@param value T           # The value to find the position of.
---@return number? position # The position found for the specified value.
---
function Utils.getIndex(t, value)
    for i,v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

---
--- Returns the non-numerical key of a specified value found within a table.
---
---@generic K, V
---@param t table<K,V> # The table to get the key from.
---@param value V      # The value to find the key of.
---@return K? key      # The key found for the specified value.
---
function Utils.getKey(t, value)
    for key, v in pairs(t) do
        if v == value then
            return key
        end
    end
    return nil
end

---
--- Returns a list of every key in a table.
---
---@generic T
---@param t table<T, any> # The table to get the keys from.
---@return T[] result     # An array of each key in the table.
---
function Utils.getKeys(t)
    local result = {}
    for key,_ in pairs(t) do
        table.insert(result, key)
    end
    return result
end

---
--- Returns the value found for a string index, ignoring case-sensitivity.
---
---@generic V
---@param t table<any,V> # The table to get the value from.
---@param key string     # The index to check within the table.
---@return V? value      # The value found at the specified index, or `nil` if no similar index was found.
---
function Utils.getAnyCase(t, key)
    for k,v in pairs(t) do
        if type(k) == "string" and k:lower() == key:lower() then
            return v
        end
    end
    return nil
end

---
--- Limits the absolute value of a number between two positive numbers, then sets it to its original sign.
---
---@param value number   # The value to limit.
---@param min number     # The minimum bound. If the absolute value of the specified value is less than this number, it is set to it.
---@param max number     # The maximum bound. If the absolute value of the specified value is greater than this number, it is set to it.
---@return number result # The new limited number.
---
function Utils.absClamp(value, min, max)
    local sign = value < 0 and -1 or 1
    return math.max(min, math.min(max, math.abs(value))) * sign
end

---
--- Returns the number closer to zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was closer to zero than the other.
---
function Utils.absMin(a, b)
    return math.abs(b) < math.abs(a) and b or a
end

---
--- Returns the number further from zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was further from zero than the other.
---
function Utils.absMax(a, b)
    return math.abs(b) > math.abs(a) and b or a
end

---@alias facing
---| "right"
---| "down"
---| "left"
---| "up"

---
--- Returns a facing direction nearest to the specified angle.
---
---@param angle number      # The angle to convert.
---@return facing direction # The facing direction the specified angle is closest to.
---
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

---
--- Returns whether the specified angle is considered to be in the specified direction.
---
---@param facing facing   # The facing direction to compare.
---@param angle number    # The angle to compare.
---@return boolean result # Whether the angle is closest to the specified facing direction.
---
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

---
--- Returns two numbers defining a vector based on the specified direction.
---
---@param facing facing # The facing direction to get the vector of.
---@return number x     # The horizontal factor of the specified direction.
---@return number y     # The vertical factor of the specified direction.
---
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

---
--- Inserts a string into a different string at the specified position.
---
---@param str1 string    # The string to receive the substring.
---@param str2 string    # The substring to insert into the main string.
---@param pos number     # The position at which to insert the string.
---@return string result # The newly created string.
---
function Utils.stringInsert(str1, str2, pos)
    return str1:sub(1, pos) .. str2 .. str1:sub(pos + 1)
end

---
--- Returns a table with values based on Tiled properties. \
--- The function will check for a series of numbered properties starting with the specified `id` string, eg. `"id1"`, followed by `"id2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
function Utils.parsePropertyList(id, properties)
    properties = properties or {}
    if properties[id] then
        -- Numberless property found, return it as the only value in the list
        return {properties[id]}
    else
        local result = {}
        -- Loop through properties with an increasing number suffix
        local i = 1
        while properties[id..i] do
            table.insert(result, properties[id..i])
            i = i + 1
        end
        return result
    end
end

---
--- Returns an array of tables with values based on Tiled properties. \
--- The function will check for a series of layered numbered properties started with the specified `id` string, eg. `"id1_1"`, followed by `"id1_2"`, `"id2_1"`, `"id2_2"`, etc. \
--- \
--- The returned table will contain a list of tables correlating to each individual list. \
--- For example, the first table in the returned array will contain the values for `"id1_1"` and `"id1_2"`, the second table will contain `"id2_1"` and `"id2_2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
function Utils.parsePropertyMultiList(id, properties)
    local single_list = Utils.parsePropertyList(id, properties)
    if #single_list > 0 then
        -- If a shallower list was found (e.g. "id1", "id2" instead of "id1_1", "id1_2"),
        -- return it as the only value in the list.
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

---
--- Returns a series of values used to determine the behavior of a flag property for a Tiled event.
---
---@param flag string|nil     # The name of the flag property.
---@param inverted string|nil # The name of the property used to determine if the flag should be inverted.
---@param value string|nil    # The name of the property used to determine what the flag's value should be compared to.
---@param default_value any   # If a property for the `value` name is not found, the value will be this instead.
---@param properties table    # The properties table of a Tiled event's data.
---@return string flag        # The name of the flag to check.
---@return boolean inverted   # Whether the result of the check should be inverted.
---@return any value          # The value that the flag should be compared to.
---
function Utils.parseFlagProperties(flag, inverted, value, default_value, properties)
    properties = properties or {}

    local result_inverted = false
    local result_flag = nil
    local result_value = default_value

    if properties[flag] then
        -- If the flag property starts with an exclamation mark, the result should
        -- be inverted and the flag name should be the rest of the string.
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

---@alias pointxy { x: number, y: number }

---
--- Returns a point at a certain distance along a path.
---
---@param path pointxy[] # An array of tables with X and Y values each, defining the coordinates of each point on the path.
---@param t number       # The distance along the path that the point should be at.
---@return number x      # The horizontal position of the point found on the path.
---@return number y      # The vertical position of the point found on the path.
---
function Utils.getPointOnPath(path, t)
    local max_x, max_y = 0, 0
    local traversed = 0

    -- Loop through each line in the path, so exclude the last point
    for i = 1, #path - 1 do

        -- Get the start and end points of the current line
        local current_point = path[i]
        local next_point = path[i + 1]

        local cx, cy = current_point.x or current_point[1], current_point.y or current_point[2]
        local nx, ny = next_point.x or next_point[1], next_point.y or next_point[2]

        -- Get the length of the current line
        local current_length = Utils.dist(cx, cy, nx, ny)

        -- Using the distance we've traversed so far, and the length of the current line,
        -- check if the point we're looking for is on this line
        if traversed + current_length > t then
            -- Calculate the position of the point on the line
            local progress = (t - traversed) / current_length
            return Utils.lerp(cx, nx, progress), Utils.lerp(cy, ny, progress)
        end

        -- Remember the furthest point on the path so far
        max_x, max_y = nx, ny

        -- Keep track of how far along the path we've gone
        traversed = traversed + current_length
    end

    -- If the path is shorter than the distance requested,
    -- return the furthest point on the path
    return max_x, max_y
end

---
--- This function substitutes values from a table into a string using placeholders in the form of `{key}` or `{}`, where the latter indexes the table by number.
---
---@param str string     # The string to substitute values into.
---@param tbl table      # The table containing the values to substitute.
---@return string result # The formatted string.
---
function Utils.format(str, tbl)
    local processed = {}
    for i,v in ipairs(tbl) do
        -- Substitute numerical indexes first
        table.insert(processed, i)
        if str:gsub("{"..i.."}", v) ~= str then
            -- Try substituting placeholders using the current numerical index
            str = str:gsub("{"..i.."}", v)
        elseif str:gsub("{}", v, 1) ~= str then
            -- Otherwise, if empty placeholders exist,
            -- substitute the first one with the current value
            str = str:gsub("{}", tostring(v), 1)
        end
    end
    for k,v in pairs(tbl) do
        -- Substitute all non-numerical table keys
        if not Utils.containsValue(processed, k) then -- ipairs already did this
            table.insert(processed, k) -- unneeded but just in case we need to expand this function later
            if str:gsub("{"..k.."}", v) ~= str then
                str = str:gsub("{"..k.."}", tostring(v))
            end
        end
    end
    -- TODO: If there's still {} left, let's try to run its contents as code
    return str
end


-- TODO: Merge with getFilesRecursive?

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

---
--- Returns the actual GID and flip flags of a tile.
---
---@param id number          # The GID of the tile.
---@return integer gid       # The GID of the tile without the flags.
---@return boolean flip_x    # Whether the tile should be flipped horizontally.
---@return boolean flip_y    # Whether the tile should be flipped vertically.
---@return boolean flip_diag # Whether the tile should be flipped diagonally.
---
function Utils.parseTileGid(id)
    return bit.band(id, 0x0FFFFFFF),
           bit.band(id, 0x80000000) ~= 0,
           bit.band(id, 0x40000000) ~= 0,
           bit.band(id, 0x20000000) ~= 0
end

---
--- Creates a Collider based on a Tiled object shape.
---
---@param parent Object      # The object that the new Collider should be parented to.
---@param data table         # The Tiled shape data.
---@param x? number          # An optional value defining the horizontal position of the collider.
---@param y? number          # An optional value defining the vertical position of the collider.
---@param properties? table  # A table defining additional properties for the collider.
---@return Collider collider # The new Collider instance.
---
function Utils.colliderFromShape(parent, data, x, y, properties)
    x, y = x or 0, y or 0
    properties = properties or {}

    -- Optional properties for collider behaviour
    -- "outside" is the same as enabling both "inverted" and "inside"
    local mode = {
        invert = properties["inverted"] or properties["outside"] or false,
        inside = properties["inside"] or properties["outside"] or false
    }

    local current_hitbox
    if data.shape == "rectangle" then
        -- For rectangles, create a Hitbox using the rectangle's dimensions
        current_hitbox = Hitbox(parent, x, y, data.width, data.height, mode)

    elseif data.shape == "polyline" then
        -- For polylines, create a ColliderGroup using a series of LineColliders
        local line_colliders = {}

        -- Loop through each pair of points in the polyline
        for i = 1, #data.polyline-1 do
            local j = i + 1
            -- Create a LineCollider using the current and next point of the polyline
            local x1, y1 = x + data.polyline[i].x, y + data.polyline[i].y
            local x2, y2 = x + data.polyline[j].x, y + data.polyline[j].y
            table.insert(line_colliders, LineCollider(parent, x1, y1, x2, y2, mode))
        end

        current_hitbox = ColliderGroup(parent, line_colliders)

    elseif data.shape == "polygon" then
        -- For polygons, create a PolygonCollider using the polygon's points
        local points = {}

        for i = 1, #data.polygon do
            -- Convert points from the format {[x] = x, [y] = y} to {x, y}
            table.insert(points, {x + data.polygon[i].x, y + data.polygon[i].y})
        end

        current_hitbox = PolygonCollider(parent, points, mode)
    end

    if properties["enabled"] == false then
        current_hitbox.collidable = false
    end

    return current_hitbox
end

---
--- Returns a string with a specified length, filling it with empty spaces by default. Used to make strings consistent lengths for UI. \
--- If the specified string has a length greater than the desired length, it will not be adjusted.
---
---@param str string         # The string to extend.
---@param len number         # The amount of characters the returned string should be.
---@param beginning? boolean # If true, the beginning of the string will be filled instead of the end.
---@param with? string       # If specified, the string will be filled with this specified string, instead of with spaces.
---@return string result     # The new padded result.
---
function Utils.padString(str, len, beginning, with)
    with = with or " "
    local i = #str
    while i < len do
        if beginning then
            str = with .. str
        else
            str = str .. with
        end
        i = i + #with
    end
    return str
end

---
--- Limits the specified value to be between 2 bounds, wrapping around if it exceeds it.
---
---@param val number     # The value to wrap.
---@param min number     # The minimum bound. If not specified, defaults to `1` for array wrapping.
---@param max number     # The maximum bound.
---@return number result # The new wrapped number.
---
---@overload fun(val:number, max:number):number
---
function Utils.clampWrap(val, min, max)
    if not max then
        max = min
        min = 1
    end
    return (val - min) % (max - min + 1) + min
end

---@see http://lua-users.org/wiki/SortedIteration
---@private
local function __genOrderedIndex(t)
    local ordered_index = {}
    for key in pairs(t) do
        table.insert(ordered_index, key)
    end
    table.sort(ordered_index)
    return ordered_index
end

-- Equivalent of the next function, but returns the keys in the alphabetic
-- order. We use a temporary ordered key table that is stored in the
-- table being iterated.
---@generic K
---@generic V
---@param table table<K,V>
---@param index? K
---@return K|nil
---@return V|nil
---@see http://lua-users.org/wiki/SortedIteration
function Utils.orderedNext(table, index)
    local key = nil
    if index == nil then
        -- the first time, generate the index
        table.__ordidx = __genOrderedIndex(table)
        key = table.__ordidx[1]
    else
        -- fetch the next value
        for i = 1, #table.__ordidx do
            if table.__ordidx[i] == index then
                key = table.__ordidx[i+1]
            end
        end
    end

    if key then
        return key, table[key]
    end

    -- no more value to return, cleanup
    table.__ordidx = nil
end

-- Equivalent of the pairs() function on tables. Allows to iterate
-- in order
---@generic K
---@generic V
---@param t table<K, V> The table to iterate
---@return fun(table: table<K,V>, index?: K):K,V next
---@return table<K, V> t
---@return nil
---@see http://lua-users.org/wiki/SortedIteration
function Utils.orderedPairs(t)
    return Utils.orderedNext, t, nil
end

---@param path string
---@return string dirname
---@see https://stackoverflow.com/a/12191225
function Utils.getDirname(path)
    ---@type string
    local dirname, _, _ = string.match(path, "(.-)([^/]-%.?([^%./]*))$")
    local trailing_slashes = dirname:find("/+$", 2)
    if trailing_slashes then dirname = dirname:sub(1, trailing_slashes - 1) end
    return dirname
end

local special_class_variables = {
    __dont_include = true,
    __includes = true,
    __includes_all = true,
    __index = true,
    __super = true,
    __includers = true,

    init = true,
    include = true,
    includes = true,
    clone = true,
    canDeepCopy = true,
    canDeepCopyKey = true
}

local function next_noclassvars(t, k)
    local v
    repeat
        k, v = next(t, k)
    until not special_class_variables[k]
    return k, v
end

--- Iterates through the fields of a class (e.g. `pairs`) excluding special class variables and functions
---@generic T : table
---@generic K, V
---@param class T
---@return (fun(table: table<K, V>, index?: K):K, V), T
function Utils.iterClass(class)
    return next_noclassvars, class
end

--- Checks if the value is NaN (Not a Number)
---@param v any
---@return boolean
function Utils.isNaN(v)
    return v ~= v
end

--- XOR (eXclusive OR) logic operation
---@param ... any [conditions]
---@return boolean
function Utils.xor(...)
    local counter = 0
    for _,value in ipairs({...}) do
        if value then
            counter = counter + 1
        end
    end
    return counter % 2 == 1
end

return Utils