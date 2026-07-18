---@class EditorConsolePanel : EditorControl
---@field editor Editor
---@field history_index number
---@field input EditorTextInput
---@field scroll_row number
---@field scrollbar EditorScrollbar
---@overload fun(editor: table): EditorConsolePanel
local EditorConsolePanel, super = Class(EditorControl)

local function flattenConsoleLine(line)
    local text = ""
    for _, part in ipairs(line or {}) do if type(part) == "string" then text = text .. part end end
    return text
end

function EditorConsolePanel:init(editor)
    super.init(self, 0, 0, 720, 240)
    self.editor = editor
    self.scroll_row = 0
    self.history_index = 0
    self.input = self:addChild(EditorTextInput({
        placeholder = "Enter Lua...",
        submit_feedback = false,
        on_submit = function(value) self:submit(value) end
    }))
    self.input.onKeyPressed = function(input, key)
        if key == "up" then return self:historyStep(-1) end
        if key == "down" then return self:historyStep(1) end
        return EditorTextInput.onKeyPressed(input, key)
    end
    self.scrollbar = self:addChild(EditorScrollbar({
        width = 12,
        on_changed = function(value) self:setScrollValue(value) end
    }))
end

function EditorConsolePanel:getConsole()
    return Kristal.Console
end

function EditorConsolePanel:submit(value)
    value = tostring(value or "")
    if value == "" or not self:getConsole() then return false end
    self:getConsole():run({ value })
    self.input:setValue("", true)
    self.history_index = #(self:getConsole().command_history or {}) + 1
    self.scroll_row = self:getMaxScroll()
    return true
end

function EditorConsolePanel:historyStep(direction)
    local console = self:getConsole()
    local history = console and console.command_history or {}
    if #history == 0 then return true end
    self.history_index = MathUtils.clamp((self.history_index > 0 and self.history_index or #history + 1) + direction,
        1, #history + 1)
    local command = history[self.history_index]
    self.input:setValue(command and table.concat(command, "\n") or "", true)
    return true
end

function EditorConsolePanel:getVisibleRows()
    return math.max(1, math.floor(math.max(0, self.height - 42) / EditorFont.get(16):getHeight()))
end

function EditorConsolePanel:getMaxScroll()
    local console = self:getConsole()
    return math.max(0, #(console and console.history or {}) - self:getVisibleRows())
end

function EditorConsolePanel:setScrollValue(value)
    self.scroll_row = MathUtils.round(self:getMaxScroll() * value)
end

function EditorConsolePanel:onWheelMoved(_, y)
    self.scroll_row = MathUtils.clamp(self.scroll_row - y * 3, 0, self:getMaxScroll())
    return true
end

function EditorConsolePanel:update(dt)
    self.scroll_row = MathUtils.clamp(self.scroll_row, 0, self:getMaxScroll())
    self.input:setBounds(8, self.height - 34, math.max(0, self.width - 28), 28)
    self.scrollbar:setBounds(self.width - 12, 0, 12, math.max(0, self.height - 40))
    local console = self:getConsole()
    local count = #(console and console.history or {})
    self.scrollbar.page = count == 0 and 1 or MathUtils.clamp(self:getVisibleRows() / count, 0, 1)
    local maximum = self:getMaxScroll()
    self.scrollbar.value = maximum == 0 and 0 or self.scroll_row / maximum
    super.update(self, dt)
end

function EditorConsolePanel:drawSelf()
    Draw.setColor(0.035, 0.035, 0.045, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    local console = self:getConsole()
    local history = console and console.history or {}
    local first = math.floor(self.scroll_row) + 1
    local last = math.min(#history, first + self:getVisibleRows())
    local y = 4
    for index = first, last do
        Draw.setColor(0.84, 0.84, 0.87, 1)
        love.graphics.print(flattenConsoleLine(history[index]), 8, y)
        y = y + font:getHeight()
    end
    Draw.setColor(1, 1, 1, 1)
end

return EditorConsolePanel
