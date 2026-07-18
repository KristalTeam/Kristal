---@class EditorCodeBuffer : Class
---@field lines table
---@overload fun(text?: string): EditorCodeBuffer
local EditorCodeBuffer = Class()

local function splitLines(text)
    text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    local lines, start = {}, 1
    while true do
        local newline = text:find("\n", start, true)
        table.insert(lines, text:sub(start, newline and newline - 1 or #text))
        if not newline then break end
        start = newline + 1
    end
    return lines
end

local function copyPosition(position)
    return { line = position.line, column = position.column }
end

function EditorCodeBuffer:init(text)
    self.lines = splitLines(text)
end

function EditorCodeBuffer:getLineCount()
    return #self.lines
end

function EditorCodeBuffer:getLine(index)
    return self.lines[MathUtils.clamp(index or 1, 1, #self.lines)]
end

function EditorCodeBuffer:getEndPosition()
    local line = #self.lines
    return { line = line, column = #self.lines[line] + 1 }
end

function EditorCodeBuffer:clampPosition(position)
    local line = MathUtils.clamp(position and position.line or 1, 1, #self.lines)
    return { line = line, column = MathUtils.clamp(position and position.column or 1, 1, #self.lines[line] + 1) }
end

function EditorCodeBuffer:compare(first, second)
    if first.line ~= second.line then return first.line < second.line and -1 or 1 end
    if first.column == second.column then return 0 end
    return first.column < second.column and -1 or 1
end

function EditorCodeBuffer:ordered(first, second)
    first, second = self:clampPosition(first), self:clampPosition(second)
    if self:compare(first, second) <= 0 then return first, second end
    return second, first
end

function EditorCodeBuffer:getText()
    return table.concat(self.lines, "\n")
end

function EditorCodeBuffer:getTextRange(first, last)
    first, last = self:ordered(first, last)
    if first.line == last.line then
        return self.lines[first.line]:sub(first.column, last.column - 1)
    end
    local result = { self.lines[first.line]:sub(first.column) }
    for line = first.line + 1, last.line - 1 do table.insert(result, self.lines[line]) end
    table.insert(result, self.lines[last.line]:sub(1, last.column - 1))
    return table.concat(result, "\n")
end

function EditorCodeBuffer:positionToOffset(position)
    position = self:clampPosition(position)
    local offset = position.column - 1
    for line = 1, position.line - 1 do offset = offset + #self.lines[line] + 1 end
    return offset
end

function EditorCodeBuffer:offsetToPosition(offset)
    offset = MathUtils.clamp(tonumber(offset) or 0, 0, #self:getText())
    for line, text in ipairs(self.lines) do
        if offset <= #text then return { line = line, column = offset + 1 } end
        offset = offset - #text
        if line < #self.lines then offset = offset - 1 end
    end
    return self:getEndPosition()
end

function EditorCodeBuffer:replace(first, last, text)
    first, last = self:ordered(first, last)
    text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    local removed = self:getTextRange(first, last)
    local old_start_line = self.lines[first.line]
    local old_end_line = self.lines[last.line]
    local prefix = old_start_line:sub(1, first.column - 1)
    local suffix = old_end_line:sub(last.column)
    local inserted_lines = splitLines(text)
    local replacement = {}
    if #inserted_lines == 1 then
        replacement[1] = prefix .. inserted_lines[1] .. suffix
    else
        replacement[1] = prefix .. inserted_lines[1]
        for index = 2, #inserted_lines - 1 do replacement[index] = inserted_lines[index] end
        replacement[#inserted_lines] = inserted_lines[#inserted_lines] .. suffix
    end
    for _ = first.line, last.line do table.remove(self.lines, first.line) end
    for index = #replacement, 1, -1 do table.insert(self.lines, first.line, replacement[index]) end

    local new_end = #inserted_lines == 1
        and { line = first.line, column = first.column + #inserted_lines[1] }
        or { line = first.line + #inserted_lines - 1, column = #inserted_lines[#inserted_lines] + 1 }
    return {
        start = copyPosition(first),
        old_end = copyPosition(last),
        new_end = new_end,
        inserted = text,
        removed = removed,
        old_start_line = old_start_line,
        old_end_line = old_end_line
    }
end

return EditorCodeBuffer
