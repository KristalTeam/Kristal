---@class StringUtils
local StringUtils = {}

---
--- Returns the length of a string, while being UTF-8 aware.
---
---@param input string # The string to get the length of.
---@return integer length # The length of the string.
---
function StringUtils.len(input)
    ---@type integer|false, string?
    local len, err = utf8.len(input)
    if err ~= nil then
        local ok_str = input:sub(1, err - 1)
        ---@type integer|false
        local ok_len = utf8.len(ok_str)
        assert(ok_len ~= false, "Invalid UTF-8 string passed to StringUtils.len.")
        error(string.format("Invalid character after \"%s\" (character #%d, byte #%d)", ok_str, ok_len + 1, err))
    end
    ---@cast len integer
    return len
end

---
--- Returns a substring of the specified string, properly accounting for UTF-8.
---
---@param input  string     # The initial string to get a substring of.
---@param from?  integer    # The index that the substring should start at. (Defaults to 1, referring to the first character of the string)
---@param to?    integer    # The index that the substring should end at. (Defaults to -1, referring to the last character of the string)
---@return string substring # The new substring.
---
function StringUtils.sub(input, from, to)
    if (from == nil) then
        from = 1
    end

    if (to == nil) then
        to = -1
    end

    if from < 1 or to < 1 then
        local length = StringUtils.len(input)
        if not length then error("Invalid UTF-8 string.") end
        if from < 0 then from = length + 1 + from end
        if to < 0 then to = length + 1 + to end
        if from < 0 then from = 1 end
        if to < 0 then to = 1 end
        if to < from then return "" end
        if from > length then from = length end
        if to > length then to = length end
    end

    if to < from then
        return ""
    end

    local offset_from = utf8.offset(input, from) --[[@as integer?]]
    local offset_to = utf8.offset(input, to + 1) --[[@as integer?]]

    if offset_from and offset_to then
        return string.sub(input, offset_from, offset_to - 1)
    elseif offset_from then
        return string.sub(input, offset_from)
    else
        return ""
    end
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
function StringUtils.splitFast(input, separator)
    local output = {}
    local index = 1
    for match in input.gmatch(input, "([^" .. separator .. "]+)") do
        output[index] = match
        index = index + 1
    end
    return output
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
function StringUtils.split(input, separator, remove_empty)
    local output = {}
    local index = 1
    local current_string = ""
    local input_len = StringUtils.len(input)
    local separator_len = StringUtils.len(separator)
    -- Loop through each character in the string.
    while index <= input_len do
        -- If the current character matches the separator, add the
        -- current string to the table, and reset the current string.
        if StringUtils.sub(input, index, index + (separator_len - 1)) == separator then
            -- If the string is empty, and empty strings shouldn't be included, skip it.
            if not remove_empty or current_string ~= "" then
                table.insert(output, current_string)
            end
            current_string = ""
            -- Skip the separator.
            index = index + (#separator - 1)
        else
            -- Add the character to the current string.
            current_string = current_string .. StringUtils.sub(input, index, index)
        end
        index = index + 1
    end
    -- Add the last string to the table.
    if not remove_empty or current_string ~= "" then
        table.insert(output, current_string)
    end
    return output
end

---
--- Returns whether a string contains a given substring
---
---@param str string      # The string to check.
---@param filter string   # The substring that the string may contain.
---@return boolean result # Whether the string contained the specified substring.
---
function StringUtils.contains(str, filter)
    return string.find(str, filter, 1, true) ~= nil
end

---
--- Returns whether a string starts with the specified substring. \
--- The function will also return a second value, created by copying the initial value and removing the prefix.
---
---@param value string     # The value to check the beginning of.
---@param prefix string    # The prefix that should be checked.
---@return boolean success # Whether the value started with the specified prefix.
---@return string rest     # A new value created by removing the prefix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function StringUtils.startsWith(value, prefix)
    if value:sub(1, #prefix) == prefix then
        return true, value:sub(#prefix + 1)
    else
        return false, value
    end
end

---
--- Returns whether a string ends with the specified substring. \
--- The function will also return a second value, created by copying the initial value and removing the suffix.
---
---@generic T : string
---@param value T          # The value to check the end of.
---@param suffix T         # The prefix that should be checked.
---@return boolean success # Whether the value ended with the specified suffix.
---@return T rest          # A new value created by removing the suffix substring or values from the initial value. If the result was unsuccessful, this value will simply be the initial unedited value.
---
function StringUtils.endsWith(value, suffix)
    assert(type(value) == "string", "expected string value, got " .. type(value))
    assert(type(suffix) == "string", "expected string suffix, got " .. type(suffix))

    if (value:sub(- #suffix) == suffix) then
        return true, value:sub(1, - #suffix - 1)
    else
        return false, value
    end
end

---
--- Converts a string into a new string where the first letter of each "word" (determined by spaces between characters) will be capitalized.
---
---@param str string     # The initial string to edit.
---@return string result # The new string, in Title Case.
---
function StringUtils.titleCase(str)
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
--- Strips a string of padding whitespace.
---
---@param str string     # The initial string to edit.
---@return string result # The new string, without padding whitespace.
---
function StringUtils.trim(str)
    return str:match("^%s*(.-)%s*$") or ""
end

---
--- Inserts a string into a different string at the specified position.
---
---@param str1 string    # The string to receive the substring.
---@param str2 string    # The substring to insert into the main string.
---@param pos integer    # The position at which to insert the string.
---@return string result # The newly created string.
---
function StringUtils.insert(str1, str2, pos)
    return StringUtils.sub(str1, 1, pos) .. str2 .. StringUtils.sub(str1, pos + 1)
end

---
--- This function substitutes values from a table into a string using placeholders in the form of `{key}` or `{}`, where the latter indexes the table by number.
---
---@param str string     # The string to substitute values into.
---@param tbl table      # The table containing the values to substitute.
---@return string result # The formatted string.
---
function StringUtils.format(str, tbl)
    local processed = {}
    for i, v in ipairs(tbl) do
        -- Substitute numerical indexes first
        table.insert(processed, i)
        if str:gsub("{" .. i .. "}", v) ~= str then
            -- Try substituting placeholders using the current numerical index
            str = str:gsub("{" .. i .. "}", v)
        elseif str:gsub("{}", v, 1) ~= str then
            -- Otherwise, if empty placeholders exist,
            -- substitute the first one with the current value
            str = str:gsub("{}", tostring(v), 1)
        end
    end
    for k, v in pairs(tbl) do
        -- Substitute all non-numerical table keys
        if not TableUtils.contains(processed, k) then -- ipairs already did this
            --table.insert(processed, k) -- unneeded but just in case we need to expand this function later
            if str:gsub("{" .. k .. "}", v) ~= str then
                str = str:gsub("{" .. k .. "}", tostring(v))
            end
        end
    end
    return str
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
function StringUtils.pad(str, len, beginning, with)
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
function StringUtils.squishAndTrunc(str, font, max_width, def_scale, min_scale, trunc_affix)
    local scale = def_scale or 1
    local text_width = font:getWidth(str) * scale

    if text_width > max_width then
        scale = max_width / text_width * scale
        if min_scale and scale < min_scale then
            scale = min_scale

            local affix_width = 0.0
            if trunc_affix ~= false then
                trunc_affix = trunc_affix or "..."
                affix_width = font:getWidth(trunc_affix) * scale
            end

            local trunc_str
            for i = 1, StringUtils.len(str) do
                trunc_str = StringUtils.sub(str, 1, i)
                local width = font:getWidth(trunc_str) * scale
                if width > (max_width - affix_width) then
                    trunc_str = StringUtils.sub(str, 1, i - 1)
                    break
                end
            end
            if trunc_affix then
                trunc_str = trunc_str .. trunc_affix
            end
            return trunc_str or "", scale
        end
    end
    return str, scale
end

return StringUtils
