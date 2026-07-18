--- Parses Lua source for highlighting and block matching.
---@class EditorLuaHighlighter : Class
---@field blocks table
---@field bracket_offsets table
---@field bracket_pairs table
---@field keyword_lookup table
---@field keyword_pairs table
---@field keyword_tokens table
---@field lines table
---@overload fun(text?: string): EditorLuaHighlighter
local EditorLuaHighlighter = Class()

EditorLuaHighlighter.COLORS = {
    text = { 0.88, 0.88, 0.90, 1 }, identifier = { 0.82, 0.84, 0.90, 1 },
    keyword = { 0.78, 0.52, 0.94, 1 }, literal = { 0.92, 0.47, 0.62, 1 },
    string = { 0.67, 0.84, 0.52, 1 }, number = { 0.92, 0.70, 0.43, 1 },
    comment = { 0.46, 0.58, 0.49, 1 }, builtin = { 0.45, 0.76, 0.88, 1 },
    self = { 0.36, 0.65, 0.96, 1 }, super = { 0.90, 0.70, 0.34, 1 },
    ["function"] = { 0.48, 0.70, 0.96, 1 }, field = { 0.48, 0.80, 0.82, 1 },
    type = { 0.88, 0.72, 0.42, 1 }, constant = { 0.91, 0.57, 0.42, 1 },
    operator = { 0.70, 0.72, 0.80, 1 }, punctuation = { 0.70, 0.72, 0.80, 1 },
    text_command = { 0.43, 0.72, 0.98, 1 },
    text_command_bracket = { 0.73, 0.55, 0.92, 1 },
    text_command_separator = { 0.66, 0.68, 0.76, 1 },
    text_command_argument = { 0.94, 0.67, 0.38, 1 },
    text_command_number = { 0.92, 0.70, 0.43, 1 }
}

EditorLuaHighlighter.TEXT_COMMANDS = {}

function EditorLuaHighlighter.registerTextCommand(command)
    command = tostring(command or "")
    if command ~= "" then EditorLuaHighlighter.TEXT_COMMANDS[command] = true end
end

local function registerTextCommands(commands)
    for _, command in ipairs(commands or {}) do EditorLuaHighlighter.registerTextCommand(command) end
end

registerTextCommands(Text and Text.COMMANDS)
registerTextCommands(DialogueText and DialogueText.COMMANDS)
registerTextCommands({ "face", "facec", "react", "miniface", "noautoskip", "emote" })

local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
    ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["goto"] = true,
    ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true,
    ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true
}

local LITERALS = { ["false"] = true, ["nil"] = true, ["true"] = true }
local BUILTINS = {
    ["_G"] = true, ["_VERSION"] = true, ["assert"] = true, ["collectgarbage"] = true,
    ["coroutine"] = true, ["debug"] = true, ["dofile"] = true, ["error"] = true,
    ["getmetatable"] = true, ["io"] = true, ["ipairs"] = true, ["load"] = true,
    ["loadfile"] = true, ["love"] = true, ["math"] = true, ["next"] = true,
    ["os"] = true, ["package"] = true, ["pairs"] = true, ["pcall"] = true,
    ["print"] = true, ["rawequal"] = true, ["rawget"] = true, ["rawlen"] = true,
    ["rawset"] = true, ["require"] = true, ["select"] = true, ["setmetatable"] = true,
    ["string"] = true, ["table"] = true, ["tonumber"] = true, ["tostring"] = true,
    ["type"] = true, ["utf8"] = true, ["xpcall"] = true
}

local OPEN_BRACKETS = { ["("] = ")", ["["] = "]", ["{"] = "}" }
local CLOSE_BRACKETS = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
local PUNCTUATION = {
    ["("] = true, [")"] = true, ["["] = true, ["]"] = true,
    ["{"] = true, ["}"] = true, [","] = true, [";"] = true
}

local function findLongBracket(text, index)
    local first, last, equals = text:find("%[(=*)%[", index)
    if first ~= index then return nil end
    return last, equals
end

local function matchAt(text, pattern, index)
    local first, last = text:find(pattern, index)
    return first == index and last or nil
end

function EditorLuaHighlighter:init(text)
    self:setText(text or "")
end

function EditorLuaHighlighter:setText(text)
    text = tostring(text or "")
    self.lines = { {} }
    self.bracket_pairs = {}
    self.bracket_offsets = {}
    self.keyword_pairs = {}
    self.keyword_tokens = {}
    self.keyword_lookup = {}
    self.blocks = {}

    local bracket_stack, block_stack = {}, {}
    local previous_significant

    local function addToken(kind, value)
        local start = 1
        while true do
            local newline = value:find("\n", start, true)
            local part = value:sub(start, newline and newline - 1 or #value)
            if part ~= "" then table.insert(self.lines[#self.lines], { text = part, kind = kind }) end
            if not newline then break end
            table.insert(self.lines, {})
            start = newline + 1
        end
    end

    local function addCommandArguments(arguments)
        if arguments == "" then return end
        addToken("text_command_separator", arguments:sub(1, 1))
        local start, index, escaped = 2, 2, false
        while index <= #arguments do
            local character = arguments:sub(index, index)
            if escaped then
                escaped = false
            elseif character == "\\" then
                escaped = true
            elseif character == "," then
                local argument = arguments:sub(start, index - 1)
                local trimmed = StringUtils.trim(argument)
                addToken(tonumber(trimmed) ~= nil and "text_command_number"
                    or "text_command_argument", argument)
                addToken("text_command_separator", ",")
                start = index + 1
            end
            index = index + 1
        end
        if start <= #arguments then
            local argument = arguments:sub(start)
            local trimmed = StringUtils.trim(argument)
            addToken(tonumber(trimmed) ~= nil and "text_command_number"
                or "text_command_argument", argument)
        end
    end

    local function addString(value)
        local cursor, search = 1, 1
        while search <= #value do
            local first, last, command, arguments = value:find("%[([%a_][%w_]*)([^%]]*)%]", search)
            if not first then break end
            local escaped = first > 1 and value:sub(first - 1, first - 1) == "\\"
            local valid_arguments = arguments == "" or arguments:sub(1, 1) == ":"
            if escaped or not valid_arguments
                or not EditorLuaHighlighter.TEXT_COMMANDS[command] then
                search = first + 1
            else
                if first > cursor then addToken("string", value:sub(cursor, first - 1)) end
                addToken("text_command_bracket", "[")
                addToken("text_command", command)
                addCommandArguments(arguments)
                addToken("text_command_bracket", "]")
                cursor = last + 1
                search = cursor
            end
        end
        if cursor <= #value then addToken("string", value:sub(cursor)) end
    end

    local function addKeyword(offset, word)
        self.keyword_tokens[offset] = { length = #word, word = word }
        for cursor = offset, offset + #word do self.keyword_lookup[cursor] = offset end
    end

    local function openBlock(offset, word, close, awaiting_do)
        addKeyword(offset, word)
        table.insert(block_stack, {
            offset = offset, word = word, close = close, awaiting_do = awaiting_do,
            depth = #block_stack + 1
        })
    end

    local function closeBlock(offset, word)
        addKeyword(offset, word)
        local opening = block_stack[#block_stack]
        if opening and opening.close == word then
            block_stack[#block_stack] = nil
            self.keyword_pairs[opening.offset] = offset
            self.keyword_pairs[offset] = opening.offset
            table.insert(self.blocks, {
                open_offset = opening.offset,
                close_offset = offset,
                depth = opening.depth
            })
        end
    end

    local index = 1
    while index <= #text do
        local start = index
        local character = text:sub(index, index)
        local kind, finish

        if character:match("%s") then
            finish = matchAt(text, "%s+", index)
            kind = "text"
        elseif character == "-" and text:sub(index + 1, index + 1) == "-" then
            local long_end, equals = findLongBracket(text, index + 2)
            if long_end then
                local close = text:find("]" .. equals .. "]", long_end + 1, true)
                finish = close and (close + #equals + 1) or #text
            else
                local newline = text:find("\n", index + 2, true)
                finish = newline and newline - 1 or #text
            end
            kind = "comment"
        elseif character == "\"" or character == "'" then
            local quote = character
            index = index + 1
            while index <= #text do
                local current = text:sub(index, index)
                if current == "\\" then
                    index = math.min(#text + 1, index + 2)
                elseif current == quote then
                    index = index + 1
                    break
                elseif current == "\n" then
                    break
                else
                    index = index + 1
                end
            end
            finish, kind = index - 1, "string"
        elseif character == "[" then
            local long_end, equals = findLongBracket(text, index)
            if long_end then
                local close = text:find("]" .. equals .. "]", long_end + 1, true)
                finish = close and (close + #equals + 1) or #text
                kind = "string"
            end
        end

        if not finish and (character:match("%d") or (character == "." and text:sub(index + 1, index + 1):match("%d"))) then
            finish = matchAt(text, "0[xX][%da-fA-F]+%.?[%da-fA-F]*[pP][+%-]?%d+", index)
                or matchAt(text, "0[xX][%da-fA-F]+%.?[%da-fA-F]*", index)
                or matchAt(text, "0[bB][01]+", index)
                or matchAt(text, "%d+%.%d*[eE][+%-]?%d+", index)
                or matchAt(text, "%d+[eE][+%-]?%d+", index)
                or matchAt(text, "%.%d+[eE][+%-]?%d+", index)
                or matchAt(text, "%d+%.%d*", index)
                or matchAt(text, "%.%d+", index)
                or matchAt(text, "%d+", index)
            if text:sub(finish, finish) == "." and text:sub(finish + 1, finish + 1) == "." then
                finish = finish - 1
            end
            kind = "number"
        elseif not finish and character:match("[%a_]") then
            finish = matchAt(text, "[%a_][%w_]*", index)
            local word = text:sub(index, finish)
            local next_index = text:find("%S", finish + 1)
            local next_character = next_index and text:sub(next_index, next_index) or nil
            if word == "self" then
                kind = "self"
            elseif word == "super" then
                kind = "super"
            elseif LITERALS[word] then
                kind = "literal"
            elseif KEYWORDS[word] then
                kind = "keyword"
            elseif BUILTINS[word] then
                kind = "builtin"
            elseif next_character == "(" then
                kind = "function"
            elseif previous_significant == "." or previous_significant == ":" then
                kind = "field"
            elseif word:match("^[A-Z][A-Z%d_]*$") then
                kind = "constant"
            elseif word:match("^[A-Z]") then
                kind = "type"
            else
                kind = "identifier"
            end

            local offset = index - 1
            if word == "function" or word == "if" then
                openBlock(offset, word, "end", false)
            elseif word == "for" or word == "while" then
                openBlock(offset, word, "end", true)
            elseif word == "repeat" then
                openBlock(offset, word, "until", false)
            elseif word == "do" then
                local opening = block_stack[#block_stack]
                if opening and opening.awaiting_do then
                    opening.awaiting_do = false
                else
                    openBlock(offset, word, "end", false)
                end
            elseif word == "end" or word == "until" then
                closeBlock(offset, word)
            end
        elseif not finish and (character:byte() or 0) >= 0x80 then
            local next_character = utf8.offset(text, 2, index)
            finish = (next_character or (#text + 1)) - 1
            kind = "identifier"
        elseif not finish then
            local operator = text:sub(index, index + 2)
            if operator ~= "..." then operator = text:sub(index, index + 1) end
            if operator ~= "..." and operator ~= ".." and operator ~= "==" and operator ~= "~=" and operator ~= "<="
                and operator ~= ">=" and operator ~= "//" and operator ~= "<<"
                and operator ~= ">>" and operator ~= "::" then
                operator = character
            end
            finish = index + #operator - 1
            kind = PUNCTUATION[character] and "punctuation" or "operator"

            if #operator == 1 and OPEN_BRACKETS[character] then
                local offset = index - 1
                self.bracket_offsets[offset] = true
                table.insert(bracket_stack, { character = character, offset = offset })
            elseif #operator == 1 and CLOSE_BRACKETS[character] then
                local offset = index - 1
                self.bracket_offsets[offset] = true
                local opening = bracket_stack[#bracket_stack]
                if opening and opening.character == CLOSE_BRACKETS[character] then
                    bracket_stack[#bracket_stack] = nil
                    self.bracket_pairs[opening.offset] = offset
                    self.bracket_pairs[offset] = opening.offset
                end
            end
        end

        local value = text:sub(start, finish)
        if kind == "string" then addString(value) else addToken(kind, value) end
        if kind ~= "text" and kind ~= "comment" then previous_significant = value end
        index = finish + 1
    end
    table.sort(self.blocks, function(first, second)
        return first.open_offset < second.open_offset
    end)
end

function EditorLuaHighlighter:getLine(index)
    return self.lines[index] or {}
end

return EditorLuaHighlighter
