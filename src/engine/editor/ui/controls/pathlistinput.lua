---@class EditorPathListInput : EditorControl
---@overload fun(editor: Editor, value?: table|string, options?: table): EditorPathListInput
local EditorPathListInput, super = Class(EditorControl)

local function copyPaths(value)
    if type(value) == "string" then return { value } end
    if type(value) ~= "table" then return {} end
    local paths = {}
    for _, path in ipairs(value) do table.insert(paths, tostring(path or "")) end
    return paths
end

function EditorPathListInput:init(editor, value, options)
    options = TableUtils.copy(options or {}, true)
    super.init(self, 0, 0, options.width or 260, 120)
    self.editor = editor
    self.options = options
    self.value = copyPaths(value)
    self.on_changed = options.on_changed
    self.on_request_focus = options.on_request_focus
    self.row_height = 32
    self.maximum_visible_rows = options.maximum_visible_rows or 5
    self.scroll_row = 0
    self.rows = {}
    self.clip = true
    self.add_button = self:addChild(EditorButton("+ Add Image", function() self:addEntry() end))
    self.scrollbar = self:addChild(EditorScrollbar({
        width = 12,
        on_changed = function(position)
            self.scroll_row = MathUtils.round(position * self:getMaxScroll())
        end
    }))
    self:rebuildRows()
end

function EditorPathListInput:getVisibleRowCount()
    return math.max(1, math.min(self.maximum_visible_rows, #self.rows))
end

function EditorPathListInput:getMaxScroll()
    return math.max(0, #self.rows - self:getVisibleRowCount())
end

function EditorPathListInput:updatePreferredHeight()
    self.preferred_height = 26 + self:getVisibleRowCount() * self.row_height + 34
end

function EditorPathListInput:clearRows()
    for _, row in ipairs(self.rows) do
        self:removeChild(row.path_input)
        self:removeChild(row.up_button)
        self:removeChild(row.down_button)
        self:removeChild(row.remove_button)
    end
    self.rows = {}
end

function EditorPathListInput:rebuildRows()
    self:clearRows()
    for index, path in ipairs(self.value) do
        local entry_index = index
        local path_options = TableUtils.copy(self.options, true)
        path_options.on_submit = function(input) return self:setEntry(entry_index, input) end
        local path_input = self:addChild(EditorPathInput(self.editor, path, path_options))
        local up_button = self:addChild(EditorButton("^", function() self:moveEntry(entry_index, -1) end))
        local down_button = self:addChild(EditorButton("v", function() self:moveEntry(entry_index, 1) end))
        local remove_button = self:addChild(EditorButton("-", function() self:removeEntry(entry_index) end))
        table.insert(self.rows, {
            path_input = path_input,
            up_button = up_button,
            down_button = down_button,
            remove_button = remove_button
        })
    end
    self.scroll_row = MathUtils.clamp(self.scroll_row, 0, self:getMaxScroll())
    self:updatePreferredHeight()
end

function EditorPathListInput:submit(candidate, rebuild)
    if self.on_changed and self.on_changed(candidate, self) == false then return false end
    self.value = candidate
    if rebuild then self:rebuildRows() end
    return true
end

function EditorPathListInput:setEntry(index, path)
    local candidate = copyPaths(self.value)
    candidate[index] = tostring(path or "")
    return self:submit(candidate, false)
end

function EditorPathListInput:addEntry()
    local candidate = copyPaths(self.value)
    table.insert(candidate, "")
    if not self:submit(candidate, true) then return false end
    self.scroll_row = self:getMaxScroll()
    local row = self.rows[#self.rows]
    if row and self.on_request_focus then
        self.on_request_focus(row.path_input.input, self)
    elseif row and self.editor and self.editor.dockspace then
        self.editor.dockspace:setFocus(row.path_input.input)
    end
    return true
end

function EditorPathListInput:moveEntry(index, direction)
    local destination = index + direction
    if destination < 1 or destination > #self.value then return false end
    local candidate = copyPaths(self.value)
    candidate[index], candidate[destination] = candidate[destination], candidate[index]
    return self:submit(candidate, true)
end

function EditorPathListInput:removeEntry(index)
    if not self.value[index] then return false end
    local candidate = copyPaths(self.value)
    table.remove(candidate, index)
    return self:submit(candidate, true)
end

function EditorPathListInput:onWheelMoved(_, y)
    if self:getMaxScroll() == 0 then return false end
    self.scroll_row = MathUtils.clamp(self.scroll_row - y, 0, self:getMaxScroll())
    return true
end

function EditorPathListInput:update(dt)
    local padding, id_width = 4, 28
    local button_width, gap = 26, 3
    local scrollbar_width = self:getMaxScroll() > 0 and 12 or 0
    local content_width = math.max(0, self.width - padding * 2 - scrollbar_width)
    local path_width = math.max(50, content_width - id_width - button_width * 3 - gap * 4)
    local first = math.floor(self.scroll_row) + 1
    local last = first + self:getVisibleRowCount() - 1
    for index, row in ipairs(self.rows) do
        local visible = index >= first and index <= last
        local y = 26 + (index - first) * self.row_height
        row.path_input.visible = visible
        row.up_button.visible = visible
        row.down_button.visible = visible
        row.remove_button.visible = visible
        if visible then
            local x = padding + id_width
            row.path_input:setBounds(x, y + 2, path_width, 28)
            x = x + path_width + gap
            row.up_button:setBounds(x, y + 2, button_width, 28)
            x = x + button_width + gap
            row.down_button:setBounds(x, y + 2, button_width, 28)
            x = x + button_width + gap
            row.remove_button:setBounds(x, y + 2, button_width, 28)
            row.up_button.enabled = index > 1
            row.down_button.enabled = index < #self.rows
        end
    end
    local footer_y = 26 + self:getVisibleRowCount() * self.row_height
    self.add_button:setBounds(padding, footer_y + 2, math.max(0, content_width), 28)
    self.scrollbar.visible = self:getMaxScroll() > 0
    if self.scrollbar.visible then
        self.scrollbar.page = self:getVisibleRowCount() / math.max(1, #self.rows)
        self.scrollbar.value = self.scroll_row / self:getMaxScroll()
        self.scrollbar:setBounds(self.width - 12, 26, 12, self:getVisibleRowCount() * self.row_height)
    end
    super.update(self, dt)
end

function EditorPathListInput:drawSelf()
    Draw.setColor(0.065, 0.065, 0.075, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    Draw.setColor(0.58, 0.58, 0.62, 1)
    love.graphics.print("ID", 7, 5)
    love.graphics.print("Image", 36, 5)
    local first = math.floor(self.scroll_row) + 1
    local last = math.min(#self.rows, first + self:getVisibleRowCount() - 1)
    Draw.setColor(0.66, 0.67, 0.72, 1)
    for index = first, last do
        love.graphics.printf(tostring(index - 1), 4, 34 + (index - first) * self.row_height, 24, "right")
    end
    if #self.rows == 0 then
        Draw.setColor(0.46, 0.46, 0.50, 1)
        love.graphics.print("No images", 36, 34)
    end
end

return EditorPathListInput
