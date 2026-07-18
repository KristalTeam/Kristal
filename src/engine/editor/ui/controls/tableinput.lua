---@class EditorTableInput : EditorControl
---@field add_button EditorButton
---@field clip boolean
---@field editor Editor
---@field maximum_visible_rows table
---@field on_changed function?
---@field on_request_focus function?
---@field preferred_height number
---@field row_height number
---@field rows table
---@field scroll_row number
---@field scrollbar EditorScrollbar
---@field value table
---@overload fun(editor: table, value?: table, options?: table): EditorTableInput
local EditorTableInput, super = Class(EditorControl)

local function displayEntry(value)
    if type(value) == "string" then return value end
    return Registry.editor_properties:getDisplayValue("value", value)
end

local function parseKey(value)
    value = tostring(value or ""):match("^%s*(.-)%s*$")
    if value == "" then return nil end
    return tonumber(value) or value
end

function EditorTableInput:init(editor, value, options)
    options = options or {}
    super.init(self, 0, 0, 260, 120)
    self.editor = editor
    self.value = type(value) == "table" and value or {}
    self.on_changed = options.on_changed
    self.on_request_focus = options.on_request_focus
    self.row_height = 30
    self.maximum_visible_rows = options.maximum_visible_rows or 6
    self.scroll_row = 0
    self.rows = {}
    self.clip = true
    self.add_button = self:addChild(EditorButton("+ Add Entry", function() self:addEntry() end))
    self.scrollbar = self:addChild(EditorScrollbar({
        width = 12,
        on_changed = function(position)
            self.scroll_row = MathUtils.round(position * self:getMaxScroll())
        end
    }))
    self:rebuildRows()
end

function EditorTableInput:getVisibleRowCount()
    return math.max(1, math.min(self.maximum_visible_rows, #self.rows))
end

function EditorTableInput:getMaxScroll()
    return math.max(0, #self.rows - self:getVisibleRowCount())
end

function EditorTableInput:updatePreferredHeight()
    self.preferred_height = 26 + self:getVisibleRowCount() * self.row_height + 34
end

function EditorTableInput:clearRows()
    for _, row in ipairs(self.rows) do
        self:removeChild(row.key_input)
        self:removeChild(row.value_input)
        self:removeChild(row.remove_button)
    end
    self.rows = {}
end

function EditorTableInput:rebuildRows()
    self:clearRows()
    for _, key in ipairs(TableUtils.getSortedKeys(self.value)) do
        local entry_key = key
        local key_input = self:addChild(EditorTextInput({
            on_submit = function(input) return self:renameEntry(entry_key, input) end
        }))
        key_input:setValue(tostring(key), true)
        local value_input = self:addChild(EditorTextInput({
            multiline = type(self.value[key]) == "table" or type(self.value[key]) == "function",
            on_submit = function(input) return self:setEntry(entry_key, input) end
        }))
        value_input:setValue(displayEntry(self.value[key]), true)
        local remove_button = self:addChild(EditorButton("-", function() self:removeEntry(entry_key) end))
        table.insert(self.rows, {
            key = key, key_input = key_input, value_input = value_input, remove_button = remove_button
        })
    end
    self.scroll_row = MathUtils.clamp(self.scroll_row, 0, self:getMaxScroll())
    self:updatePreferredHeight()
end

function EditorTableInput:submit(candidate)
    if self.on_changed and self.on_changed(candidate, self) == false then return false end
    self.value = candidate
    self:rebuildRows()
    return true
end

function EditorTableInput:setEntry(key, input)
    local value = Registry.editor_properties:coerce("value", input)
    if value == nil then
        self:rebuildRows()
        return false
    end
    if self.value[key] == value then return true end
    local candidate = TableUtils.copy(self.value, true)
    candidate[key] = value
    return self:submit(candidate)
end

function EditorTableInput:renameEntry(old_key, input)
    local new_key = parseKey(input)
    if new_key == nil or new_key ~= old_key and self.value[new_key] ~= nil then
        self:rebuildRows()
        return false
    end
    if new_key == old_key then return true end
    local candidate = TableUtils.copy(self.value, true)
    candidate[new_key], candidate[old_key] = candidate[old_key], nil
    return self:submit(candidate)
end

function EditorTableInput:addEntry()
    local candidate = TableUtils.copy(self.value, true)
    local key
    if TableUtils.isContiguousArray(candidate) then
        key = #candidate + 1
    else
        key = "key"
        local index = 2
        while candidate[key] ~= nil do
            key = "key" .. index
            index = index + 1
        end
    end
    candidate[key] = ""
    if not self:submit(candidate) then return false end
    self.scroll_row = self:getMaxScroll()
    for _, row in ipairs(self.rows) do
        if row.key == key and self.on_request_focus then
            self.on_request_focus(row.value_input, self)
            break
        elseif row.key == key and self.editor.dockspace then
            self.editor.dockspace:setFocus(row.value_input)
            break
        end
    end
    return true
end

function EditorTableInput:removeEntry(key)
    if self.value[key] == nil then return false end
    local candidate = TableUtils.copy(self.value, true)
    candidate[key] = nil
    return self:submit(candidate)
end

function EditorTableInput:onWheelMoved(_, y)
    if self:getMaxScroll() == 0 then return false end
    self.scroll_row = MathUtils.clamp(self.scroll_row - y, 0, self:getMaxScroll())
    return true
end

function EditorTableInput:update(dt)
    local padding, remove_width, scrollbar_width = 4, 28, self:getMaxScroll() > 0 and 12 or 0
    local content_width = math.max(0, self.width - padding * 2 - scrollbar_width)
    local key_width = math.max(44, math.floor(content_width * 0.34))
    local value_width = math.max(44, content_width - key_width - remove_width - 8)
    local first = math.floor(self.scroll_row) + 1
    local last = first + self:getVisibleRowCount() - 1
    for index, row in ipairs(self.rows) do
        local visible = index >= first and index <= last
        local y = 26 + (index - first) * self.row_height
        row.key_input.visible, row.value_input.visible, row.remove_button.visible = visible, visible, visible
        if visible then
            row.key_input:setBounds(padding, y, key_width, 28)
            row.value_input:setBounds(padding + key_width + 4, y, value_width, 28)
            row.remove_button:setBounds(padding + key_width + value_width + 8, y, remove_width, 28)
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

function EditorTableInput:drawSelf()
    Draw.setColor(0.065, 0.065, 0.075, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    Draw.setColor(0.58, 0.58, 0.62, 1)
    love.graphics.print("Key", 5, 5)
    love.graphics.print("Value", math.max(49, math.floor((self.width - 8) * 0.34) + 9), 5)
    if #self.rows == 0 then
        Draw.setColor(0.46, 0.46, 0.50, 1)
        love.graphics.print("Empty table", 5, 30)
    end
end

return EditorTableInput
