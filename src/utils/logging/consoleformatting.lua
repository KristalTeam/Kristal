--- The formatting class used for console output.
---
--- Requires an RGB color, and a list of ANSI escape sequences.
---
---@class ConsoleFormatting
---
---@field private color Color
---@field private escape_sequences EscapeSequence[]
local ConsoleFormatting = Class()

---@param color Color The RGB color to use.
---@param escape_sequences EscapeSequence[] The ANSI escape sequences to use.
function ConsoleFormatting:init(color, escape_sequences)
    self.color = color
    self.escape_sequences = escape_sequences
end

--- Get the color of the formatting.
---@return Color
function ConsoleFormatting:getColor()
    return self.color
end

--- Return the ANSI escape sequences for this formatting.
---@return EscapeSequence[]
function ConsoleFormatting:getEscapeSequences()
    if not Logging.getColorSupport() then
        return {}
    end

    local sequences = { EscapeSequences.RESET }
    for _, sequence in ipairs(self.escape_sequences) do
        table.insert(sequences, sequence)
    end

    return sequences
end

return ConsoleFormatting
