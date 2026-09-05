--- A formatted string, for use with logging.
---
--- If you're looking for anything that isn't a part of the logging system, you should look elsewhere.
---@class FormatString
---@field private parts FormatStringPart[]
local FormatString = Class()

---@param text string?
---@param formatting ConsoleFormatting?
function FormatString:init(text, formatting)
    assert(type(text) == "string" or text == nil, "text must be a string or nil")
    assert(type(formatting) == "table" or formatting == nil, "formatting must be a ConsoleFormatting or nil")

    if not text then
        self.parts = {}
        return
    end

    self.parts = { FormatStringPart(text, formatting) }
end

---@param parts FormatStringPart[]
---@return FormatString
function FormatString.fromParts(parts)
    assert(type(parts) == "table", "parts must be a table")

    local format_string = FormatString("", ConsoleFormats.DEFAULT)
    format_string.parts = parts
    return format_string
end

--- Collapses the formatted string into an ANSI string.
---@return string
function FormatString:getANSIString()
    local result = ""

    for _, part in ipairs(self.parts) do
        local sequences = part.formatting:getEscapeSequences()
        result = result .. table.concat(sequences, "") .. part.text
    end

    result = result .. EscapeSequences.RESET

    return result
end

---@class FormatStringTablePair
---@field text string
---@field color Color

--- Collapses the formatted string into a table of string and Colors.
---@return FormatStringTablePair[]
function FormatString:getTable()
    local result = {}

    for _, part in ipairs(self.parts) do
        table.insert(result, { text = part.text, color = part.formatting:getColor() })
    end

    return result
end

--- Add another formatted string to this one.
---@param format_string FormatString|string
---@return FormatString
function FormatString:add(format_string)
    assert(type(format_string) == "string" or (isClass(format_string) and format_string:includes(FormatString)), "format_string must be a string or FormatString")

    local parts = TableUtils.copy(self.parts)

    if type(format_string) == "string" then
        table.insert(parts, FormatStringPart(format_string))
    else
        for _, part in ipairs(format_string.parts) do
            table.insert(parts, part)
        end
    end

    return FormatString.fromParts(parts)
end

function FormatString.__concat(a, b)
    assert(type(a) == "string" or (isClass(a) and a:includes(FormatString)), "Left operand must be a string or FormatString")
    assert(type(b) == "string" or (isClass(b) and b:includes(FormatString)), "Right operand must be a string or FormatString")

    if type(a) == "string" then
        a = FormatString(a)
    end

    return a:add(b)
end

return FormatString
