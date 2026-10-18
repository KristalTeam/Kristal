--- Displays editor warnings and errors.
---@class EditorDiagnosticsPanel : EditorControl
---@field clip boolean
---@field editor Editor
---@field expanded table
---@field row_rects table
---@field scroll_y number
---@field scrollbar EditorScrollbar
---@overload fun(editor: table): EditorDiagnosticsPanel
local EditorDiagnosticsPanel, super = Class(EditorControl)

function EditorDiagnosticsPanel:init(editor)
    super.init(self, 0, 0, 720, 240)
    self.editor = editor
    self.scroll_y = 0
    self.expanded = {}
    self.row_rects = {}
    self.clip = true
    self.scrollbar = self:addChild(EditorScrollbar({
        width = 12,
        on_changed = function(value) self.scroll_y = self:getMaxScroll() * value end
    }))
end

function EditorDiagnosticsPanel:getEntries()
    return self.editor.message_bar and self.editor.message_bar.entries or {}
end

function EditorDiagnosticsPanel:getContentHeight()
    local height = 8
    local font = EditorFont.get(16)
    for index, entry in ipairs(self:getEntries()) do
        height = height + 30
        if self.expanded[index] and entry.detail then
            height = height + math.max(font:getHeight(), #StringUtils.split(entry.detail, "\n", false) * font:getHeight()) + 12
        end
    end
    return height
end

function EditorDiagnosticsPanel:getMaxScroll()
    return math.max(0, self:getContentHeight() - self.height)
end

function EditorDiagnosticsPanel:onMousePressed(_, y, button)
    if button ~= 1 then return false end
    for index, rect in pairs(self.row_rects) do
        if y >= rect.y and y < rect.y + rect.height then
            local entry = self:getEntries()[index]
            if entry and entry.action then
                entry.action(entry)
            elseif entry and entry.detail then
                self.expanded[index] = not self.expanded[index]
            end
            return true
        end
    end
    return true
end

function EditorDiagnosticsPanel:onWheelMoved(_, y)
    self.scroll_y = MathUtils.clamp(self.scroll_y - y * 42, 0, self:getMaxScroll())
    return true
end

function EditorDiagnosticsPanel:update(dt)
    self.scroll_y = MathUtils.clamp(self.scroll_y, 0, self:getMaxScroll())
    local maximum = self:getMaxScroll()
    local content = self:getContentHeight()
    self.scrollbar.page = content == 0 and 1 or MathUtils.clamp(self.height / content, 0, 1)
    self.scrollbar.value = maximum == 0 and 0 or self.scroll_y / maximum
    self.scrollbar:setBounds(self.width - self.scrollbar.width, 0, self.scrollbar.width, self.height)
    super.update(self, dt)
end

function EditorDiagnosticsPanel:drawSelf()
    Draw.setColor(0.065, 0.065, 0.075, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    local y = 8 - self.scroll_y
    self.row_rects = {}
    for index, entry in ipairs(self:getEntries()) do
        local color = entry.severity == "error" and { 1, 0.34, 0.34, 1 } or { 1, 0.76, 0.24, 1 }
        self.row_rects[index] = { y = y, height = 30 }
        Draw.setColor(index % 2 == 0 and { 0.10, 0.10, 0.12, 1 } or { 0.085, 0.085, 0.10, 1 })
        love.graphics.rectangle("fill", 0, y, self.width - self.scrollbar.width, 30)
        Draw.setColor(color)
        love.graphics.print(entry.detail and (self.expanded[index] and "v" or ">") or "-", 8, y + 5)
        love.graphics.print(string.upper(entry.severity), 28, y + 5)
        Draw.setColor(0.9, 0.9, 0.92, 1)
        love.graphics.print(entry.message, 112, y + 5)
        y = y + 30
        if self.expanded[index] and entry.detail then
            local lines = StringUtils.split(entry.detail, "\n", false)
            local detail_height = math.max(font:getHeight(), #lines * font:getHeight()) + 12
            Draw.setColor(0.045, 0.045, 0.055, 1)
            love.graphics.rectangle("fill", 0, y, self.width - self.scrollbar.width, detail_height)
            Draw.setColor(0.72, 0.72, 0.76, 1)
            love.graphics.print(entry.detail, 28, y + 6)
            y = y + detail_height
        end
    end
    if #self:getEntries() == 0 then
        Draw.setColor(0.55, 0.55, 0.58, 1)
        love.graphics.print("No warnings or errors in this editor session.", 10, 10)
    end
    Draw.setColor(1, 1, 1, 1)
end

return EditorDiagnosticsPanel
