---@class Utils
---
--- A collection of various utility functions. \
--- This has been deprecated in favor of more specific utility modules. \
--- Not everything has been moved, so you may still use this module for now. \
--- Before using this module, check if there is a method in a more specific utility module that does what you need.
---
local Utils = {}

---
--- Returns a substring of the specified string, properly accounting for UTF-8.
---
---@param input  string     # The initial string to get a substring of.
---@param from?  integer    # The index that the substring should start at. (Defaults to 1, referring to the first character of the string)
---@param to?    integer    # The index that the substring should end at. (Defaults to -1, referring to the last character of the string)
---@return string substring # The new substring.
---
---@deprecated Use StringUtils.sub instead
function Utils.sub(input, from, to)
    return StringUtils.sub(input, from, to)
end

---
--- Returns the length of a string, while being UTF-8 aware.
---
---@param input string # The string to get the length of.
---@return integer length # The length of the string.
---
---@deprecated Use StringUtils.len instead
function Utils.len(input)
    return StringUtils.len(input)
end

---
--- Returns whether every value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func? fun(v:T):boolean # If provided, each value of the table will instead be passed into the function, whose returned value will be considered instead of the table value itself.
---@return boolean result        # Whether every value was true or not.
---
---@deprecated Use TableUtils.all OR TableUtils.every instead
function Utils.all(tbl, func)
    if func == nil then
        return TableUtils.all(tbl)
    else
        return TableUtils.every(tbl, func)
    end
end

---
--- Returns whether any individual value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func? fun(v:T):boolean # If provided, each value of the table will instead be passed into the function, whose returned value will be considered instead of the table value itself.
---@return boolean result        # Whether any value was true or not.
---
---@deprecated Use `TableUtils.any` OR `TableUtils.some` instead
function Utils.any(tbl, func)
    if func == nil then
        return TableUtils.any(tbl)
    else
        return TableUtils.some(tbl, func)
    end
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
---@deprecated Use `TableUtils.copy` instead
function Utils.copy(tbl, deep, seen)
    return TableUtils.copy(tbl, deep, seen)
end

---
--- Copies the values of one table into a different one.
---
---@param new_tbl table # The table receiving the copied values.
---@param tbl table     # The table to copy values from.
---@param deep? boolean # Whether tables inside the specified table should be copied as well.
---@param seen? table   # *(Used internally)* A table of values used to keep track of which objects have been cloned.
---
---@deprecated Use `TableUtils.copyInto` instead
function Utils.copyInto(new_tbl, tbl, deep, seen)
    return TableUtils.copyInto(new_tbl, tbl, deep, seen)
end

---
--- Empties a table of all defined values.
---
---@param tbl table # The table to clear.
---
---@deprecated Use `TableUtils.clear` instead
function Utils.clear(tbl)
    return TableUtils.clear(tbl)
end

---
--- Returns the name of a given class, using the name of the global variable for the class. \
--- If it cannot find a global variable associated with the class, it will instead return the name of the class it extends, along with the class's ID.
---
---@param class table           # The class instance to check.
---@param parent_check? boolean # Whether the function should only return the extended class, and not attach the class's ID, if the class does not have a global name.
---@return string? name         # The name of the class, or `nil` if it cannot find one.
---
---@deprecated Use `ClassUtils.getClassName` instead
function Utils.getClassName(class, parent_check)
    return ClassUtils.getClassName(class, parent_check)
end

---
--- Returns a string converting a table value into readable text. Useful for debugging table values.
---
---@param o any          # The value to convert to a string.
---@return string result # The newly generated string.
---
---@deprecated Use `TableUtils.dump` instead
function Utils.dump(o)
    return TableUtils.dump(o)
end

---
--- Returns every numerically indexed value of a table. \
--- This fixes the issue with `unpack()` not returning `nil` values.
---
---@generic T
---@param t T[]  # The table to unpack.
---@return T ... # The values of the table.
---
---@deprecated Use `TableUtils.unpack` instead
function Utils.unpack(t)
    return TableUtils.unpack(t)
end

---
--- Splits a string into a new table of strings using a single character as a separator. \
--- More optimized than `Utils.split()`, at the cost of lacking features. \
--- **Note**: This function uses `gmatch`, so special characters must be escaped with a `%`.
---
---@param input string     # The string to separate.
---@param separator string # The character used to split the main string.
---@return string[] result # The table containing the new split strings.
---
---@deprecated Use `StringUtils.splitFast` instead
function Utils.splitFast(input, separator)
    return StringUtils.splitFast(input, separator)
end

---
--- Splits a string into a new table of strings using a substring as a separator. \
--- Less optimized than `Utils.splitFast()`, but allows separating with multiple characters, and is more likely to work for *any* string.
---
---@param input string          # The string to separate.
---@param separator string      # The substring used to split the main string.
---@param remove_empty? boolean # Whether strings containing no characters shouldn't be included in the result table.
---@return string[] result      # The table containing the new split strings.
---
---@deprecated Use `StringUtils.split` instead
function Utils.split(input, separator, remove_empty)
    return StringUtils.split(input, separator, remove_empty)
end

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
---@deprecated Use `HookSystem.hook` instead
function Utils.hook(target, name, hook, exact_func)
    return HookSystem.hook(target, name, hook, exact_func)
end

---@generic T : Class|function
---
---@param include? T|`T`|string     # The class to extend from. If passed as a string, will be looked up from the current registry (e.g. `scripts/data/actors` if creating an actor) or the global namespace.
---
---@return T class                # The new class, extended from `include` if provided.
---@return T|superclass<T> super  # Allows calling methods from the base class. `self` must be passed as the first argument to each method.
---
---@deprecated Use `HookSystem.hookScript` instead
function Utils.hookScript(include)
    return HookSystem.hookScript(include)
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
---@deprecated Use `HookSystem.override` instead
function Utils.override(old_func, new_func)
    return HookSystem.override(old_func, new_func)
end

---
--- Returns whether two tables have an equivalent set of values.
---
---@param a any            # The first table to compare.
---@param b any            # The second table to compare.
---@param deep? boolean    # Whether table values within these tables should also be compared using `Utils.equal()`.
---@return boolean success # Whether the sets of values for the two tables were equivalent.
function Utils.equal(a, b, deep)
    if type(a) ~= type(b) then
        -- Values are only equal if their types are the same
        return false
    elseif type(a) == "table" then
        -- Tables are equal if they have the same keys and values
        for k, v in pairs(a) do
            if b[k] == nil then
                return false
            elseif deep and not Utils.equal(v, b[k], true) then
                -- If deep comparison is enabled, check `Utils.equal()` for the values
                return false
            elseif not deep and v ~= b[k] then
                -- Otherwise, just check if the values are equal
                return false
            end
        end
        -- Check if the tables have the same number of keys
        for k, v in pairs(b) do
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
---@deprecated Use `FileSystemUtils.getFilesRecursive` instead
function Utils.getFilesRecursive(dir, ext)
    return FileSystemUtils.getFilesRecursive(dir, ext)
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
        for _, v in ipairs(text) do
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
---@deprecated Use `ColorUtils.HSLToRGB` instead
function Utils.hslToRgb(h, s, l)
    return ColorUtils.HSLToRGB(h, s, l)
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
---@deprecated Use `ColorUtils.RGBToHSL` instead
function Utils.rgbToHsl(r, g, b)
    return ColorUtils.RGBToHSL(r, g, b)
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
---@deprecated Use `ColorUtils.HSVToRGB` instead
function Utils.hsvToRgb(h, s, v)
    return ColorUtils.HSVToRGB(h, s, v)
end

---
--- Converts a hex color string to an RGBA color table.
---
---@param hex string     # The string to convert to RGB. The string *must* be formatted with a # at the start, eg. `"#ff00ff"`.
---@param value? number  # An optional number specifying the alpha the returned table should have.
---@return number[] rgba # The converted RGBA table.
---
---@deprecated Use `ColorUtils.hexToRGB` instead
function Utils.hexToRgb(hex, value)
    local color = ColorUtils.hexToRGB(hex)
    return {
        color[1],
        color[2],
        color[3],
        color[4] * (value or 1),
    }
end

---
--- Converts a table of RGB values to a hex color string.
---
---@param rgb number[] # The RGB table to convert. Values should be between 0 and 1.
---@return string hex  # The converted hex string. Formatted with a # at the start, eg. "#ff00ff".
---
---@deprecated Use `ColorUtils.RGBToHex` instead
function Utils.rgbToHex(rgb)
    return ColorUtils.RGBToHex(rgb[1], rgb[2], rgb[3])
end

---
--- Converts a Tiled color property to an RGBA color table.
---
---@param property string # The property string to convert.
---@return number[]? rgba # The converted RGBA table.
---
---@deprecated Use `TiledUtils.parseColorProperty` instead
function Utils.parseColorProperty(property)
    return TiledUtils.parseColorProperty(property)
end

---
--- Merges the values of one table into another one.
---
---@param tbl table     # The table to merge values into.
---@param other table   # The table to copy values from.
---@param deep? boolean # Whether shared table values between the two tables should also be merged.
---@return table tbl    # The initial table, now containing new values.
---
---@deprecated Use `TableUtils.merge` instead
function Utils.merge(tbl, other, deep)
    return TableUtils.merge(tbl, other, deep)
end

---
--- Merges a list of tables into a new table.
---
---@param ... table     # The list of tables to merge values from.
---@return table result # A new table containing the values of the series of tables provided.
---
---@deprecated Use `TableUtils.mergeMany` instead
function Utils.mergeMultiple(...)
    return TableUtils.mergeMany(...)
end


---
--- Remove duplicate elements from a table.
---
---@param tbl table       # The table to remove duplicates from.
---@param deep? boolean   # Whether tables inside the tbl will also have their duplicates removed.
---@return table result   # The new table that has its duplicates removed.
---
---@deprecated Use `TableUtils.removeDuplicates` instead
function Utils.removeDuplicates(tbl, deep)
    return TableUtils.removeDuplicates(tbl, deep)
end

---
--- Returns whether a table contains exclusively numerical indexes.
---
---@param tbl table       # The table to check.
---@return boolean result # Whether the table contains only numerical indexes or not.
---
---@deprecated Use `TableUtils.isArray` instead
function Utils.isArray(tbl)
    return TableUtils.isArray(tbl)
end

---
--- Removes the specified value from the table.
---
---@generic T
---@param tbl table # The table to remove the value from.
---@param val T     # The value to be removed from the table.
---@return T? val   # The now removed value.
---
---@deprecated Use `TableUtils.removeValue` instead
function Utils.removeFromTable(tbl, val)
    return TableUtils.removeValue(tbl, val)
end

---
--- Whether the table contains the specified value.
---
---@param tbl table       # The table to check the value from.
---@param val any         # The value to check.
---@return boolean result # Whether the table contains the specified value.
---
---@deprecated Use `TableUtils.contains` instead
function Utils.containsValue(tbl, val)
    return TableUtils.contains(tbl, val)
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
    for _, v in ipairs(tbl) do
        if type(v) ~= "table" then
            error("table contains non-table value: " .. v)
        else
            max = math.max(max, #v)
        end
    end
    for i = 1, max do
        result[i] = {}
        for j = 1, #tbl do
            if ccw then
                result[i][j] = tbl[j][(max + 1) - i]
            else
                result[i][j] = tbl[(#tbl + 1) - j][i]
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
    for _, v in ipairs(tbl) do
        if type(v) ~= "table" then
            error("table contains non-table value: " .. v)
        else
            max = math.max(max, #v)
        end
    end
    for i = 1, max do
        result[i] = {}
        for j = 1, #tbl do
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
---@deprecated Use `math.floor` or `MathUtils.floorToMultiple` instead.
function Utils.floor(value, to)
    if not to then
        return math.floor(value)
    else
        return MathUtils.floorToMultiple(value, to)
    end
end

---
--- Rounds the specified value up to the nearest integer.
---
---@param value number   # The value to round.
---@param to? number     # If specified, the value will instead be rounded up to the nearest multiple of this number.
---@return number result # The rounded value.
---
---@deprecated Use `math.ceil` or `MathUtils.ceilToMultiple` instead.
function Utils.ceil(value, to)
    if not to then
        return math.ceil(value)
    else
        return MathUtils.ceilToMultiple(value, to)
    end
end

---
--- Rounds the specified value to the nearest integer.
---
---@param value number   # The value to round.
---@param to? number     # If specified, the value will instead be rounded to the nearest multiple of this number.
---@return number result # The rounded value.
---
---@deprecated Use `MathUtils.round` or `MathUtils.roundToMultiple` instead.
function Utils.round(value, to)
    if not to then
        return MathUtils.round(value)
    else
        return MathUtils.roundToMultiple(value, to)
    end
end

---
--- Rounds the specified value to the nearest integer towards zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
---@deprecated Use `MathUtils.roundToZero` instead.
function Utils.roundToZero(value)
    return MathUtils.roundToZero(value)
end

---
--- Rounds the specified value to the nearest integer away from zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
---@deprecated Use `MathUtils.roundFromZero` instead.
function Utils.roundFromZero(value)
    return MathUtils.roundFromZero(value)
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
---@deprecated Use `MathUtils.clamp` instead
function Utils.clamp(val, min, max)
    return MathUtils.clamp(val, min, max)
end

---
--- Returns the polarity of the specified value: -1 if it's negative, 1 if it's positive, and 0 otherwise.
---
---@param num number   # The value to check.
---@return number sign # The sign of the value.
---
---@deprecated Use `MathUtils.sign` instead
function Utils.sign(num)
    return MathUtils.sign(num)
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
---@deprecated Use `MathUtils.approach` instead
function Utils.approach(val, target, amount)
    return MathUtils.approach(val, target, amount)
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
---@deprecated Use `MathUtils.approachAngle` instead
function Utils.approachAngle(val, target, amount)
    return MathUtils.approachAngle(val, target, amount)
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
---@deprecated Use `MathUtils.lerp` or `TableUtils.lerp` instead. As they do not clamp by default, clamp the percentage yourself if needed.
function Utils.lerp(a, b, t, oob)
    local percentage = oob and t or MathUtils.clamp(t, 0, 1)

    if type(a) == "table" and type(b) == "table" then
        return TableUtils.lerp(a, b, percentage)
    else
        return MathUtils.lerp(a, b, percentage)
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
    local percentage = oob and t or MathUtils.clamp(t, 0, 1)
    return MathUtils.lerpPoint(x1, y1, x2, y2, percentage)
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
            error("\"" .. tostring(mode) .. "\" is not a valid easing method")
        end
        return Ease[mode](MathUtils.clamp(t, 0, 1), a, (b - a), 1)
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
---@deprecated Use `MathUtils.rangeMap`, `Utils.ease` and `MathUtils.clamp` instead
function Utils.clampMap(val, min_a, max_a, min_b, max_b, mode)
    if min_a > max_a then
        min_a, max_a = max_a, min_a
        min_b, max_b = max_b, min_b
    end
    if mode and mode ~= "linear" then
        local range = MathUtils.clamp(MathUtils.rangeMap(val, min_a, max_a, 0, 1), 0, 1)
        return Utils.ease(min_b, max_b, range, mode)
    end
    return MathUtils.rangeMap(MathUtils.clamp(val, min_a, max_a), min_a, max_a, min_b, max_b)
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
    min = min or -1
    max = max or 1
    return MathUtils.clamp(MathUtils.rangeMap(math.sin(val), -1, 1, min, max), min, max)
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
    table.insert(performance_stack, 1, { love.timer.getTime(), name })
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
    for k, times in pairs(PERFORMANCE_TEST) do
        if k ~= "Total" and #times > 0 then
            local n = 0
            for _, v in ipairs(times) do
                n = n + v
            end
            Kristal.Console:log("[" .. PERFORMANCE_TEST_STAGE .. "] " .. k .. " | " .. #times .. " calls | " .. (n / #times) .. " | Total: " .. n)
        end
    end
    if PERFORMANCE_TEST["Total"] then
        Kristal.Console:log("[" .. PERFORMANCE_TEST_STAGE .. "] Total: " .. PERFORMANCE_TEST["Total"][1])
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
    return ColorUtils.mergeColor(start_color, end_color, amount)
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
        table.insert(edges, { p1, p2, angle = math.atan2(p2[2] - p1[2], p2[1] - p1[1]) })
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
    for _, edge in ipairs(edges) do
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
function Utils.getLineIntersect(l1p1x, l1p1y, l1p2x, l1p2y, l2p1x, l2p1y, l2p2x, l2p2y, seg1, seg2)
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
---@deprecated Use the random functions in `MathUtils` instead
function Utils.random(a, b, c)
    if not a then
        return love.math.random()
    elseif not b then
        return love.math.random() * a
    else
        local n = love.math.random() * (b - a) + a
        if c then
            n = MathUtils.roundToMultiple(n, c)
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
    return MathUtils.random() < 0.5 and 1 or -1
end

---
--- Returns a table of 2 numbers, defining a vector in a random cardinal direction. (eg. `{0, -1}`)
---
---@return number[] vector # The vector table.
---
function Utils.randomAxis()
    local t = { Utils.randomSign() }
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
    if MathUtils.random() < 0.5 then
        local sx = (MathUtils.random() < 0.5) and x or x + w
        local sy = MathUtils.random(y, y + h)
        return sx, sy
    else
        local sx = MathUtils.random(x, x + w)
        local sy = (MathUtils.random() < 0.5) and y or y + h
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
---@deprecated Use `TableUtils.filter` instead
function Utils.filter(tbl, filter)
    return TableUtils.filter(tbl, filter)
end

---
--- Removes values from a table if a function does not return true for them.
---
---@generic T
---@param tbl T[]                 # An array of values.
---@param filter fun(v:T):boolean # A function that should return `true` for all values in the table to keep, and `false` for values to discard.
---
---@deprecated Use `TableUtils.filterInPlace` instead
function Utils.filterInPlace(tbl, filter)
    TableUtils.filterInPlace(tbl, filter)
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
---@deprecated Use `TableUtils.pick`, `TableUtils.filter` and `TableUtils.removeValue` instead.
function Utils.pick(tbl, sort, remove)
    if sort then
        local indexes = {}
        for i, v in ipairs(tbl) do
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
    for i, v in ipairs(tbl) do
        if not sort or sort(v) then
            table.insert(indexes, i)
        end
    end
    for _ = 1, amount do
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
---@deprecated Use `TableUtils.shuffle` instead
function Utils.shuffle(tbl)
    return TableUtils.shuffle(tbl)
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
    for i = #tbl, 1, -1 do
        table.insert(t, tbl[i])
    end
    -- If the table was grouped, flatten it back into a single array.
    if group then
        t = TableUtils.flatten(t)
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
---@deprecated Use `TableUtils.flatten` instead
function Utils.flatten(tbl, deep)
    return TableUtils.flatten(tbl, deep)
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
        for _ = 1, count do
            i = i + 1
            if tbl[i] then
                table.insert(o, tbl[i])
            else
                break
            end
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
---@param x1 number  # The horizontal position of the first point.
---@param y1 number  # The vertical position of the first point.
---@param x2 number  # The horizontal position of the second point.
---@param y2 number  # The vertical position of the second point.
---@return number angle     # The angle from the first point to the second point.
---
---@overload fun(x1:Object, y1:Object): angle:number
function Utils.angle(x1, y1, x2, y2)
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
        return MathUtils.angle(x1, y1, x2, y2)
    end
end

---
--- Returns the distance between two angles, properly accounting for wrapping around.
---
---@param a number     # The first angle to compare.
---@param b number     # The second angle to compare.
---@return number diff # The difference between the two angles.
---
---@deprecated Use `MathUtils.angleDiff` instead.
function Utils.angleDiff(a, b)
    return MathUtils.angleDiff(a, b)
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
---@deprecated Use `MathUtils.dist` instead.
function Utils.dist(x1, y1, x2, y2)
    return MathUtils.dist(x1, y1, x2, y2)
end

---
--- Returns whether a string contains a given substring.
---
---@param str string      # The string to check.
---@param filter string   # The substring that the string may contain.
---@return boolean result # Whether the string contained the specified substring.
---
---@deprecated Use `StringUtils.contains` instead.
function Utils.contains(str, filter)
    return StringUtils.contains(str, filter)
end

---
--- Returns whether a string starts with the specified substring, or a table starts with the specified series of values. \
--- The function will also return a second value, created by copying the initial value and removing the prefix.
---
---@generic T : string|table
---@param value T          # The value to check the beginning of.
---@param prefix T         # The prefix that should be checked.
---@return boolean success # Whether the value started with the specified prefix.
---@return T rest          # A new value created by removing the prefix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
---@deprecated Use `StringUtils.startsWith` or `TableUtils.startsWith` instead.
function Utils.startsWith(value, prefix)
    if type(value) == "string" then
        return StringUtils.startsWith(value, prefix)
    elseif type(value) == "table" then
        return TableUtils.startsWith(value, prefix)
    end
    return false, value
end

---
--- Returns whether a string ends with the specified substring, or a table ends with the specified series of values. \
--- The function will also return a second value, created by copying the initial value and removing the suffix.
---
---@generic T : string|table
---@param value T          # The value to check the end of.
---@param suffix T         # The prefix that should be checked.
---@return boolean success # Whether the value ended with the specified suffix.
---@return T rest          # A new value created by removing the suffix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
---@deprecated Use `StringUtils.endsWith` or `TableUtils.endsWith` instead.
function Utils.endsWith(value, suffix)
    if type(value) == "string" then
        return StringUtils.endsWith(value, suffix)
    elseif type(value) == "table" then
        return TableUtils.endsWith(value, suffix)
    end
    return false, value
end

---
--- Attempts to resolve a relative path from a Tiled export to a valid asset id, given it points to a path inside the
--- `target_dir` of the current mod.
---
--- Relative directories (`..`) of the asset path are resolved by starting from the `source_dir`, which should match the
--- directory the Tiled data was exported to. Exporting to a different directory and copying/moving the exported data will
--- likely cause this relative search to fail.
---
---@param target_dir string # The Kristal folder to get the path relative to.
---@param asset_path string # The asset path from a Tiled export to resolve.
---@param source_dir string # Parent directory of the Tiled export, which the `asset_path` should be relative to.
---@return string? asset_id # The asset path relative the `target_dir` without its extension, or `nil` if the resolution failed.
---
---@deprecated Use `TiledUtils.relativePathToAssetId` instead.
function Utils.absoluteToLocalPath(target_dir, asset_path, source_dir)
    local success, result = TiledUtils.relativePathToAssetId(target_dir, asset_path, source_dir)
    return success and result or nil
end

---
--- Converts a string into a new string where the first letter of each "word" (determined by spaces between characters) will be capitalized.
---
---@param str string     # The initial string to edit.
---@return string result # The new string, in Title Case.
---
---@deprecated Use `StringUtils.titleCase` instead.
function Utils.titleCase(str)
    return StringUtils.titleCase(str)
end

---
--- Strips a string of padding whitespace.
---
---@param str string     # The initial string to edit.
---@return string result # The new string, without padding whitespace.
---
---@deprecated Use `StringUtils.trim` instead.
function Utils.trim(str)
    return StringUtils.trim(str)
end

---
--- Returns how many indexes a table has, including non-numerical indexes.
---
---@param t table        # The table to check.
---@return number result # The amount of indexes found.
---
---@deprecated Use `TableUtils.getKeyCount` instead.
function Utils.tableLength(t)
    return TableUtils.getKeyCount(t)
end

---
--- Returns the position of a specified value found within an array.
---
---@generic T
---@param t T[]             # The array to get the position from.
---@param value T           # The value to find the position of.
---@return number? position # The position found for the specified value.
---
---@deprecated Use `TableUtils.getIndex` instead.
function Utils.getIndex(t, value)
    return TableUtils.getIndex(t, value)
end

---
--- Returns the non-numerical key of a specified value found within a table.
---
---@generic K, V
---@param t table<K,V> # The table to get the key from.
---@param value V      # The value to find the key of.
---@return K? key      # The key found for the specified value.
---
---@deprecated Use `TableUtils.getKey` instead.
function Utils.getKey(t, value)
    return TableUtils.getKey(t, value)
end

---
--- Returns a list of every key in a table.
---
---@generic T
---@param t table<T, any> # The table to get the keys from.
---@return T[] result     # An array of each key in the table.
---
---@deprecated Use `TableUtils.getKeys` instead.
function Utils.getKeys(t)
    return TableUtils.getKeys(t)
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
    for k, v in pairs(t) do
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
---@deprecated Use `MathUtils.absClamp` instead.
function Utils.absClamp(value, min, max)
    return MathUtils.absClamp(value, min, max)
end

---
--- Returns the number closer to zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was closer to zero than the other.
---
---@deprecated Use `MathUtils.absMin` instead.
function Utils.absMin(a, b)
    return MathUtils.absMin(a, b)
end

---
--- Returns the number further from zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was further from zero than the other.
---
---@deprecated Use `MathUtils.absMax` instead.
function Utils.absMax(a, b)
    return MathUtils.absMax(a, b)
end

---@alias FacingDirection
---| "right"
---| "down"
---| "left"
---| "up"

---
--- Returns a facing direction nearest to the specified angle.
---
---@param angle number               # The angle to convert.
---@return FacingDirection direction # The facing direction the specified angle is closest to.
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
---@param facing FacingDirection # The facing direction to compare.
---@param angle number           # The angle to compare.
---@return boolean result        # Whether the angle is closest to the specified facing direction.
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
---@param facing FacingDirection # The facing direction to get the vector of.
---@return number x              # The horizontal factor of the specified direction.
---@return number y              # The vertical factor of the specified direction.
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
---@deprecated Use `StringUtils.insert` instead.
function Utils.stringInsert(str1, str2, pos)
    return StringUtils.insert(str1, str2, pos)
end

---
--- Returns a table with values based on Tiled properties. \
--- The function will check for a series of numbered properties starting with the specified `id` string, eg. `"id1"`, followed by `"id2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
---@deprecated Use `TiledUtils.parsePropertyList` instead.
function Utils.parsePropertyList(id, properties)
    return TiledUtils.parsePropertyList(id, properties)
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
---@deprecated Use `TiledUtils.parsePropertyMultiList` instead.
function Utils.parsePropertyMultiList(id, properties)
    return TiledUtils.parsePropertyMultiList(id, properties)
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
---@deprecated Use `TiledUtils.parseFlagProperties` instead.
function Utils.parseFlagProperties(flag, inverted, value, default_value, properties)
    return TiledUtils.parseFlagProperties(flag, inverted, value, default_value, properties)
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
        local current_length = MathUtils.dist(cx, cy, nx, ny)

        -- Using the distance we've traversed so far, and the length of the current line,
        -- check if the point we're looking for is on this line
        if traversed + current_length > t then
            -- Calculate the position of the point on the line
            local progress = MathUtils.clamp((t - traversed) / current_length, 0, 1)
            return MathUtils.lerp(cx, nx, progress), MathUtils.lerp(cy, ny, progress)
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
---@deprecated Use `StringUtils.format` instead.
function Utils.format(str, tbl)
    return StringUtils.format(str, tbl)
end

-- TODO: Merge with getFilesRecursive?
---@deprecated Use `FileSystemUtils.getFilesRecursive` instead.
function Utils.findFiles(folder, base, path)
    return FileSystemUtils.findFiles(folder, base, path)
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
---@deprecated Use `TiledUtils.parseTileGid` instead.
function Utils.parseTileGid(id)
    return TiledUtils.parseTileGid(id)
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
---@deprecated Use `TiledUtils.colliderFromShape` instead.
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
        for i = 1, #data.polyline - 1 do
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
            table.insert(points, { x + data.polygon[i].x, y + data.polygon[i].y })
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
---@deprecated Use `StringUtils.pad` instead.
function Utils.padString(str, len, beginning, with)
    return StringUtils.pad(str, len, beginning, with)
end

---
--- Finds and returns the scale required to print `str` with the font `font`, such that it's width does not exceed `max_width`. \
--- If a `min_scale` is specified, strings that would have to be squished smaller than it will instead have their remaining part truncated. \
--- Returns the input string (truncated if necessary), and the scale to print it at.
---
---@param str string                # The string to squish and truncate.
---@param font love.Font            # The font being used to print the string.
---@param max_width number          # The maximum width the string should be able to take up.
---@param def_scale? number         # The default scale used to print the string. Defaults to `1`.
---@param min_scale? number         # The minimum scale that the string can be squished to before being truncated.
---@param trunc_affix? string|false # The affix added to the string during truncation. If `false`, does not add an affix. Defaults to `...`.
---@return string result            # The truncated result. Returns the original string if it was not truncated.
---@return number scale             # The scale the `result` string should be printed at to fit within the specified width.
---@deprecated Use `StringUtils.squishAndTrunc` instead.
function Utils.squishAndTrunc(str, font, max_width, def_scale, min_scale, trunc_affix)
    return StringUtils.squishAndTrunc(str, font, max_width, def_scale, min_scale, trunc_affix)
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
---@deprecated Use `MathUtils.wrap` or `MathUtils.wrapIndex` instead.
function Utils.clampWrap(val, min, max)
    if not max then
        max = min
        min = 1
    end
    return MathUtils.wrap(val, min, max + 1)
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
---@deprecated Use `FileSystemUtils.getDirname` instead.
function Utils.getDirname(path)
    return FileSystemUtils.getDirname(path)
end

--- Iterates through the fields of a class (e.g. `pairs`) excluding special class variables and functions
---@generic T : table
---@generic K, V
---@param class T
---@return (fun(table: table<K, V>, index?: K):K, V), T
---@deprecated Use `ClassUtils.iterClass` instead
function Utils.iterClass(class)
    return ClassUtils.iterClass(class)
end

--- Checks if the value is NaN (Not a Number)
---@param v any
---@return boolean
---@deprecated Use `MathUtils.isNaN` instead
function Utils.isNaN(v)
    return MathUtils.isNaN(v)
end

--- XOR (eXclusive OR) logic operation
---@param ... any [conditions]
---@return boolean
---@deprecated Use `MathUtils.xor` instead
function Utils.xor(...)
    return MathUtils.xor(...)
end

return Utils
