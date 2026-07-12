---@class EditorItemList : EditorControl
---@overload fun(options?: table): EditorItemList
local EditorItemList, super = Class(EditorControl)

function EditorItemList:init(options)
    options = options or {}
    super.init(self, options.x, options.y, options.width or 220, options.height or 240)
    self.items = {}
    self.filtered_items = {}
    self.filter = ""
    self.selected_index = nil
    self.row_height = options.row_height or 26
    self.on_select = options.on_select
    self.on_activate = options.on_activate
    self.on_drag_start = options.on_drag_start
    self.on_drag_move = options.on_drag_move
    self.on_drag_end = options.on_drag_end
    self.on_rename = options.on_rename
    self.on_context_menu = options.on_context_menu
    self.on_request_focus = options.on_request_focus
    self.pending_drag = nil
    self.dragging_item = nil
    self.focusable = true
    self.focused = false
    self.scroll_row = 0
    self.clip = true
    self.scrollbar = self:addChild(EditorScrollbar({
        width = options.scrollbar_width or 12,
        on_changed = function(value) self:setScrollValue(value) end
    }))
    self.rename_input = self:addChild(EditorTextInput({
        on_submit = function() self:finishRename(true) end,
        on_cancel = function() self:finishRename(false) end
    }))
    self.rename_input.visible = false
    self.rename_input.onBlur = function(input)
        input.focused = false
        love.keyboard.setTextInput(false)
        if self.rename_item then self:finishRename(true, true) end
    end
end

function EditorItemList:getItemIndexAt(y)
    local first = math.floor(self.scroll_row) + 1
    local offset = -(self.scroll_row - math.floor(self.scroll_row)) * self.row_height
    return first + math.floor((y - offset) / self.row_height)
end

function EditorItemList:getCursorType(x, y)
    if self.dragging_item then return "grab" end
    if x >= self.width - self.scrollbar.width then return "select" end
    local index = self:getItemIndexAt(y)
    return self.filtered_items[index] and "select" or "default"
end

local function normalizeItem(item, index)
    if type(item) == "table" then
        return {
            id = item.id or item.value or index,
            label = tostring(item.label or item.name or item.id or item.value or index),
            data = item.data ~= nil and item.data or item,
            icon = item.icon,
            preview = item.preview,
            color = item.color,
            right_icon = item.right_icon,
            right_color = item.right_color,
            right_action = item.right_action,
            indent = item.indent or 0,
            disclosure = item.disclosure
        }
    end
    return { id = item, label = tostring(item), data = item }
end

function EditorItemList:setItems(items)
    if self.rename_item then self:finishRename(true) end
    self.items = {}
    for index, item in ipairs(items or {}) do
        table.insert(self.items, normalizeItem(item, index))
    end
    self:applyFilter()
end

function EditorItemList:requestFocus(control)
    if self.on_request_focus then self.on_request_focus(control, self) end
end

function EditorItemList:beginRename(item)
    item = item or self:getSelectedItem()
    if not item or not self.on_rename then return false end
    local index
    for candidate_index, candidate in ipairs(self.filtered_items) do
        if candidate == item then index = candidate_index break end
    end
    if not index then return false end
    self.rename_item = item
    self.rename_input:setValue(item.label, true)
    self.rename_input.cursor = #self.rename_input.value + 1
    self.rename_input.visible = true
    self:updateRenameBounds()
    self:requestFocus(self.rename_input)
    return true
end

function EditorItemList:finishRename(commit, from_blur)
    local item = self.rename_item
    if not item then return false end
    local old_label = item.label
    local new_label = tostring(self.rename_input.value or ""):match("^%s*(.-)%s*$")
    if commit and new_label ~= "" then item.label = new_label end
    self.rename_item = nil
    self.rename_input.visible = false
    if commit and item.label ~= old_label then self.on_rename(item, old_label, item.label, self) end
    if not from_blur then self:requestFocus(self) end
    return true
end

function EditorItemList:updateRenameBounds()
    if not self.rename_item then return end
    local index
    for candidate_index, candidate in ipairs(self.filtered_items) do
        if candidate == self.rename_item then index = candidate_index break end
    end
    if not index then return self:finishRename(true) end
    local y = -(self.scroll_row - math.floor(self.scroll_row)) * self.row_height
        + (index - math.floor(self.scroll_row) - 1) * self.row_height
    local label_x = 6 + (self.rename_item.indent or 0) * 14
    if self.rename_item.disclosure then label_x = label_x + 14 end
    if self.rename_item.preview then
        label_x = label_x + self.row_height - 2
    elseif self.rename_item.icon then
        local texture = Assets.getTexture(self.rename_item.icon)
        if texture then label_x = label_x + texture:getWidth() + 8 end
    end
    local right_space = self.rename_item.right_icon and self.row_height or 0
    self.rename_input:setBounds(label_x - 3, y + 1,
        math.max(20, self.width - self.scrollbar.width - label_x - right_space), self.row_height - 2)
end

function EditorItemList:setFilter(filter)
    filter = string.lower(tostring(filter or ""))
    if self.filter == filter then return end
    self.filter = filter
    self:applyFilter()
end

function EditorItemList:applyFilter()
    local selected_id = self:getSelectedItem() and self:getSelectedItem().id
    self.filtered_items = {}
    for _, item in ipairs(self.items) do
        if self.filter == "" or string.find(string.lower(item.label), self.filter, 1, true) then
            table.insert(self.filtered_items, item)
        end
    end
    self.selected_index = nil
    if selected_id ~= nil then
        for index, item in ipairs(self.filtered_items) do
            if item.id == selected_id then self.selected_index = index break end
        end
    end
    if not self.selected_index and #self.filtered_items > 0 then self.selected_index = 1 end
    self:clampScroll()
end

function EditorItemList:getVisibleRows()
    return math.max(1, math.floor(self.height / self.row_height))
end

function EditorItemList:getMaxScroll()
    return math.max(0, #self.filtered_items - self:getVisibleRows())
end

function EditorItemList:clampScroll()
    self.scroll_row = MathUtils.clamp(self.scroll_row, 0, self:getMaxScroll())
    local count = #self.filtered_items
    self.scrollbar.page = count == 0 and 1 or MathUtils.clamp(self:getVisibleRows() / count, 0, 1)
    local max_scroll = self:getMaxScroll()
    self.scrollbar.value = max_scroll == 0 and 0 or self.scroll_row / max_scroll
end

function EditorItemList:setScrollValue(value)
    self.scroll_row = MathUtils.round(self:getMaxScroll() * value)
    self:clampScroll()
end

function EditorItemList:getSelectedItem()
    return self.selected_index and self.filtered_items[self.selected_index] or nil
end

function EditorItemList:select(index, activate)
    if #self.filtered_items == 0 then self.selected_index = nil return end
    index = MathUtils.clamp(index, 1, #self.filtered_items)
    local changed = self.selected_index ~= index
    self.selected_index = index
    if index <= self.scroll_row then self.scroll_row = index - 1 end
    local visible_rows = self:getVisibleRows()
    if index > self.scroll_row + visible_rows then self.scroll_row = index - visible_rows end
    self:clampScroll()
    local item = self:getSelectedItem()
    if changed and self.on_select then self.on_select(item, self) end
    if activate and self.on_activate then self.on_activate(item, self) end
end

function EditorItemList:onFocus() self.focused = true end
function EditorItemList:onBlur() self.focused = false end

function EditorItemList:onMousePressed(x, y, button, presses)
    if x >= self.width - self.scrollbar.width then return false end
    local index = self:getItemIndexAt(y)
    local item = self.filtered_items[index]
    if button == 1 and item and item.right_icon and item.right_action then
        local texture = Assets.getTexture(item.right_icon)
        local icon_width = texture and texture:getWidth() or self.row_height
        local icon_right = self.width - self.scrollbar.width - 6
        if x >= icon_right - icon_width and x <= icon_right then
            item.right_action(item, self)
            return true
        end
    end
    if button == 2 then
        if self.filtered_items[index] then
            self:select(index)
            if self.on_context_menu then self.on_context_menu(self.filtered_items[index], self, x, y) end
        elseif self.on_context_menu then
            self.on_context_menu(nil, self, x, y)
        end
        return self.on_context_menu ~= nil
    end
    if button ~= 1 then return false end
    if self.filtered_items[index] then
        local already_selected = self.selected_index == index
        self:select(index, presses and presses >= 2)
        if already_selected and self.on_select then self.on_select(self.filtered_items[index], self) end
        if presses and presses >= 2 and self.on_rename then
            self:beginRename(self.filtered_items[index])
            return true
        end
        if self.on_drag_end then
            self.pending_drag = { item = self.filtered_items[index], x = x, y = y }
        end
    end
    return true
end

function EditorItemList:onMouseMoved(x, y, dx, dy)
    if self.pending_drag and not self.dragging_item
        and math.abs(x - self.pending_drag.x) + math.abs(y - self.pending_drag.y) >= 5 then
        self.dragging_item = self.pending_drag.item
        if self.on_drag_start then self.on_drag_start(self.dragging_item, self) end
    end
    if self.dragging_item then
        if self.on_drag_move then self.on_drag_move(self.dragging_item, self, x, y, dx, dy) end
        return true
    end
    return false
end

function EditorItemList:onMouseReleased(x, y, button)
    if button ~= 1 then return false end
    local item = self.dragging_item
    self.pending_drag = nil
    self.dragging_item = nil
    if item then
        self.on_drag_end(item, self, x, y)
        return true
    end
    return false
end

function EditorItemList:onWheelMoved(_, y)
    self.scroll_row = self.scroll_row - y * 3
    self:clampScroll()
    return true
end

function EditorItemList:onKeyPressed(key)
    if key == "up" then
        self:select((self.selected_index or 1) - 1)
        return true
    elseif key == "down" then
        self:select((self.selected_index or 0) + 1)
        return true
    elseif key == "pageup" then
        self:select((self.selected_index or 1) - self:getVisibleRows())
        return true
    elseif key == "pagedown" then
        self:select((self.selected_index or 0) + self:getVisibleRows())
        return true
    elseif key == "home" then
        self:select(1)
        return true
    elseif key == "end" then
        self:select(#self.filtered_items)
        return true
    elseif key == "return" or key == "kpenter" then
        local item = self:getSelectedItem()
        if item and self.on_activate then self.on_activate(item, self) end
        return true
    end
    return false
end

function EditorItemList:update(dt)
    self.scrollbar:setBounds(self.width - self.scrollbar.width, 0, self.scrollbar.width, self.height)
    self:clampScroll()
    self:updateRenameBounds()
    super.update(self, dt)
end

function EditorItemList:drawSelf()
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    love.graphics.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local first = math.floor(self.scroll_row) + 1
    local offset = -(self.scroll_row - math.floor(self.scroll_row)) * self.row_height
    local last = math.min(#self.filtered_items, first + self:getVisibleRows())
    for index = first, last do
        local y = offset + (index - first) * self.row_height
        if index == self.selected_index then
            love.graphics.setColor(self.focused and 0.22 or 0.17, self.focused and 0.34 or 0.22, self.focused and 0.52 or 0.30, 1)
            love.graphics.rectangle("fill", 0, y, self.width - self.scrollbar.width, self.row_height)
        end
        local item = self.filtered_items[index]
        local label_x = 6 + (item.indent or 0) * 14
        if item.disclosure then
            love.graphics.setColor(0.72, 0.72, 0.76, 1)
            love.graphics.print(item.disclosure, label_x, math.floor(y + (self.row_height - font:getHeight()) / 2))
            label_x = label_x + 14
        end
        if item.preview and item.preview.drawPreviewIcon then
            local padding = 4
            local preview_size = self.row_height - padding * 2
            item.preview:drawPreviewIcon(label_x, y + padding, preview_size, preview_size, 0.9)
            label_x = label_x + self.row_height - 2
        elseif item.icon then
            local texture = Assets.getTexture(item.icon)
            if texture then
                local icon_x = label_x
                local icon_y = math.floor(y + (self.row_height - texture:getHeight()) / 2)
                Draw.setColor(item.color or { 1, 1, 1, 1 })
                Draw.draw(texture, icon_x, icon_y)
                label_x = icon_x + texture:getWidth() + 8
            end
        end
        if item ~= self.rename_item then
            love.graphics.setColor(0.88, 0.88, 0.90, 1)
            love.graphics.print(item.label, label_x, math.floor(y + (self.row_height - font:getHeight()) / 2))
        end
        if item.right_icon then
            local texture = Assets.getTexture(item.right_icon)
            if texture then
                local icon_x = self.width - self.scrollbar.width - texture:getWidth() - 6
                local icon_y = math.floor(y + (self.row_height - texture:getHeight()) / 2)
                Draw.setColor(item.right_color or { 0.82, 0.82, 0.85, 1 })
                Draw.draw(texture, icon_x, icon_y)
            end
        end
    end
end

return EditorItemList
