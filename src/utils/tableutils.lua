---@class TableUtils
local TableUtils = {}

---
--- Returns whether every value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@return boolean result        # Whether every value was true or not.
---
function TableUtils.all(tbl)
    for i = 1, #tbl do
        if not tbl[i] then
            return false
        end
    end
    return true
end

---
--- Returns whether every value in a table satisfies a condition, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func fun(v:T):boolean  # The condition function.
---@return boolean result        # Whether every value satisfied the condition or not.
---
function TableUtils.every(tbl, func)
    for i = 1, #tbl do
        if not func(tbl[i]) then
            return false
        end
    end
    return true
end

---
--- Returns whether any individual value in a table is true, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@return boolean result        # Whether any value was true or not.
---
function TableUtils.any(tbl)
    for i = 1, #tbl do
        if tbl[i] then
            return true
        end
    end
    return false
end

---
--- Returns whether any individual value in a table satisfies a condition, iterating numerically.
---
---@generic T
---@param tbl T[]                # The table to iterate through.
---@param func fun(v:T):boolean  # The condition function.
---@return boolean result        # Whether any value satisfied the condition or not.
---
function TableUtils.some(tbl, func)
    for i = 1, #tbl do
        if func(tbl[i]) then
            return true
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
function TableUtils.copy(tbl, deep, seen)
    if tbl == nil then
        return nil
    end

    local new_tbl = {}
    TableUtils.copyInto(new_tbl, tbl, deep, seen)
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
function TableUtils.copyInto(new_tbl, tbl, deep, seen)
    if tbl == nil then return nil end

    -- Remember the current table we're copying, so we can avoid
    -- infinite loops when deep copying tables that reference themselves.
    seen = seen or {}
    seen[tbl] = new_tbl

    for k, v in pairs(tbl) do
        -- If we're deep copying, and the value is a table, then we need to copy that table as well.
        if type(v) == "table" and deep then
            if seen[v] then
                -- If we've already seen this table, use the same copy.
                new_tbl[k] = seen[v]
            elseif (not isClass(tbl) or (tbl:canDeepCopyKey(k) and not tbl.__dont_include[k])) and (not isClass(v) or (v.canDeepCopy and v:canDeepCopy())) then
                -- Unless the current value is a class that doesn't want to be deep copied,
                -- or the member of a class that doesn't want it to be deep copied, we can copy it.
                new_tbl[k] = {}
                TableUtils.copyInto(new_tbl[k], v, true, seen)
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
function TableUtils.clear(tbl)
    for key in pairs(tbl) do
        tbl[key] = nil
    end
end

local function dumpKey(key)
    if type(key) == 'table' then
        return '(' .. tostring(key) .. ')'
    elseif type(key) == 'string' and (not key:find("[^%w_]") and not tonumber(key:sub(1, 1)) and key ~= "") then
        return key
    else
        return '[' .. TableUtils.dump(key) .. ']'
    end
end

---
--- Returns a string converting a table value into readable text. Useful for debugging table values.
---
---@param o any          # The value to convert to a string.
---@return string result # The newly generated string.
---
function TableUtils.dump(o)
    if type(o) == 'table' then
        if isClass(o) then
            -- If the table is a class, return the
            -- name of the class instead of its contents.
            return ClassUtils.getClassName(o) or "<unknown class>"
        end
        local s = '{'
        local cn = 1
        if TableUtils.isArray(o) then
            for _, v in ipairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. TableUtils.dump(v)
                cn = cn + 1
            end
        else
            for k, v in pairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. dumpKey(k) .. ' = ' .. TableUtils.dump(v)
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
function TableUtils.unpack(t)
    return unpack(t, 1, table.maxn(t))
end

---
--- Merges the values of one table into another one.
---
---@param tbl table     # The table to merge values into.
---@param other table   # The table to copy values from.
---@param deep? boolean # Whether shared table values between the two tables should also be merged.
---@return table tbl    # The initial table, now containing new values.
---
function TableUtils.merge(tbl, other, deep)
    if TableUtils.isArray(other) then
        -- If the source table is an array, just append the values
        -- to the end of the destination table.
        for _, v in ipairs(other) do
            table.insert(tbl, v)
        end
    else
        for k, v in pairs(other) do
            if deep and type(tbl[k]) == "table" and type(v) == "table" then
                -- If we're deep merging and both values are tables,
                -- merge the tables together.
                TableUtils.merge(tbl[k], v, true)
            else
                -- Otherwise, just copy the value over.
                tbl[k] = v
            end
        end
    end
    return tbl
end

---
--- Merges many tables into a new table.
---
---@param ... table     # The tables to merge values from.
---@return table result # A new table containing the values of the series of tables provided.
---
function TableUtils.mergeMany(...)
    local tbl = {}
    for i = 1, select("#", ...) do
        TableUtils.merge(tbl, select(i, ...))
    end
    return tbl
end

---
--- Remove duplicate elements from a table.
---
---@param tbl table       # The table to remove duplicates from.
---@param deep? boolean   # Whether tables inside the tbl will also have their duplicates removed.
---@return table result   # The new table that has its duplicates removed.
---
function TableUtils.removeDuplicates(tbl, deep)
    local dupe_check = {}
    local result = {}
    if TableUtils.isArray(tbl) then
        -- If the source table is an array, just append the values
        -- to the end of the destination table.
        for _, v in ipairs(tbl) do
            if deep and type(v) == "table" then
                v = TableUtils.removeDuplicates(v, true)
            end
            if not dupe_check[v] then
                table.insert(result, v)
                dupe_check[v] = true
            end
        end
    else
        for k, v in pairs(tbl) do
            if deep and type(v) == "table" then
                v = TableUtils.removeDuplicates(v, true)
            end
            if not dupe_check[v] then
                result[k] = v
                dupe_check[v] = true
            end
        end
    end

    -- Remove duplicate tables
    for _, f in pairs(result) do
        if type(f) == "table" then
            for _, s in pairs(result) do
                if Utils.equal(f, s, true) and f ~= s then
                    TableUtils.removeValue(result, s)
                end
            end
        end
    end

    return result
end

---
--- Returns whether a table contains exclusively numerical indexes.
---
---@param tbl table       # The table to check.
---@return boolean result # Whether the table contains only numerical indexes or not.
---
function TableUtils.isArray(tbl)
    for k, _ in pairs(tbl) do
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
function TableUtils.removeValue(tbl, val)
    for i, v in ipairs(tbl) do
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
function TableUtils.contains(tbl, val)
    for k, v in pairs(tbl) do
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
function TableUtils.rotate(tbl, ccw)
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
function TableUtils.flip(tbl)
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
--- Lerp between each value in a table.
---
---@generic T : table
---@param from T       # The start values of the range.
---@param to T         # The end values of the range.
---@param value number # The percentage (from 0 to 1) that determines the point on the specified range.
---@return T result    # The new table containing the values from the ranges.
---
function TableUtils.lerp(from, to, value)
    assert(type(from) == "table", "Expected table from, got " .. type(from))
    assert(type(to) == "table", "Expected table to, got " .. type(to))
    assert(#to == #from, "from and to tables must be the same length")
    local output = {}
    for index = 1, #from do
        table.insert(output, MathUtils.lerp(from[index], to[index], value))
    end
    return output
end

---
--- Returns a new table containing only values that a function returns true for.
---
---@generic T
---@param tbl T[]                 # An array of values.
---@param filter fun(v:T):boolean # A function that should return `true` for all values in the table to keep, and `false` for values to discard.
---@return T[] result             # A new array containing only approved values.
---
function TableUtils.filter(tbl, filter)
    local t = {}
    for _, v in ipairs(tbl) do
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
function TableUtils.filterInPlace(tbl, filter)
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
---@return T result              # The randomly selected value.
---
function TableUtils.pick(tbl)
    return tbl[love.math.random(#tbl)]
end

---
--- Returns a table containing the values of another table, randomly rearranged.
---
---@generic T
---@param tbl T[]     # An array of values.
---@return T[] result # The new randomly shuffled array.
---
function TableUtils.shuffle(tbl)
    local shuffled = TableUtils.copy(tbl, false)

    for i = #shuffled, 2, -1 do
        local j = MathUtils.randomInt(1, i + 1)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    return shuffled
end

---
--- Returns a table containing the values of an array in reverse order.
---
---@generic T
---@param tbl T[]       # An array of values.
---@return T[] result   # The new table containing the values of the specified array.
---
function TableUtils.reverse(tbl)
    local t = {}
    -- Loop through the table backwards, and insert each value into the new table.
    for i = #tbl, 1, -1 do
        table.insert(t, tbl[i])
    end
    return t
end

---
--- Merges a list of tables containing values into a single table containing each table's contents.
---
---@generic T
---@param tbl T[][]     # The array of tables to merge.
---@param deep? boolean # If true, tables contained inside nested tables will also be merged.
---@return T[] result   # The new table containing all values.
---
function TableUtils.flatten(tbl, deep)
    local t = {}
    for _, value in ipairs(tbl) do
        if type(value) == "table" and not isClass(value) then -- Do not flatten classes
            for _, v in ipairs(deep and TableUtils.flatten(value, true) or value) do
                table.insert(t, v)
            end
        else
            table.insert(t, value)
        end
    end
    return t
end

---
--- Returns how many keys a table has.
---
---@param t table        # The table to check.
---@return number result # The amount of keys found.
---
function TableUtils.getKeyCount(t)
    local count = 0

    for _ in pairs(t) do
        count = count + 1
    end

    return count
end

---
--- Returns the position of a specified value found within an array.
---
---@generic T
---@param t T[]             # The array to get the position from.
---@param value T           # The value to find the position of.
---@return number? position # The position found for the specified value.
---
function TableUtils.getIndex(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

---
--- Returns the key of a specified value found within a table.
---
---@generic K, V
---@param t table<K,V> # The table to get the key from.
---@param value V      # The value to find the key of.
---@return K? key      # The key found for the specified value.
---
function TableUtils.getKey(t, value)
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
function TableUtils.getKeys(t)
    local result = {}
    for key, _ in pairs(t) do
        table.insert(result, key)
    end
    return result
end

---
--- Returns whether a table starts with the specified values. \
--- The function will also return a second value, created by copying the initial value and removing the prefix.
---
---@param value table      # The table to check the beginning of.
---@param prefix table     # The values that should be checked.
---@return boolean success # Whether the value started with the specified prefix.
---@return table rest   # A new value created by removing the prefix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function TableUtils.startsWith(value, prefix)
    -- If the value is a table, check if the first few values match the prefix
    if #value < #prefix then
        -- Prefix cannot be longer than the value
        return false, value
    end
    -- Create a copy of the value to remove the prefix from
    local copy = TableUtils.copy(value)
    for i, v in ipairs(prefix) do
        if value[i] ~= v then
            -- Return false if any value in the prefix does not match
            return false, value
        end
        table.remove(copy, 1)
    end
    return true, copy
end

---
--- Returns whether a table ends with the specified values. \
--- The function will also return a second value, created by copying the initial value and removing the suffix.
--- 
--- @param value table      # The table to check the end of.
--- @param suffix table     # The values that should be checked.
--- @return boolean success # Whether the value ended with the specified suffix.
--- @return table rest   # A new value created by removing the suffix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function TableUtils.endsWith(value, suffix)
    -- If the value is a table, check if the last few values match the suffix
    if #value < #suffix then
        -- Suffix cannot be longer than the value
        return false, value
    end
    -- Create a copy of the value to remove the suffix from
    local copy = TableUtils.copy(value)
    for i = #value, 1, -1 do
        if suffix[#suffix + (i - #value)] ~= copy[i] then
            -- Return false if any value in the suffix does not match
            return false, value
        end
        table.remove(copy, i)
    end
    return true, copy
end

return TableUtils
