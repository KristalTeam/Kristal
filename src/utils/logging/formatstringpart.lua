---@class FormatStringPart : Class
local FormatStringPart = Class()

---@param text string
---@param formatting ConsoleFormatting?
function FormatStringPart:init(text, formatting)
    assert(type(text) == "string", "text must be a string")
    assert(type(formatting) == "table" or formatting == nil, "formatting must be a ConsoleFormatting or nil")

    self.text = text
    self.formatting = formatting or ConsoleFormats.DEFAULT
end

return FormatStringPart
