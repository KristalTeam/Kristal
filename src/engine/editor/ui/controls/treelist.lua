--- Displays nested items with selection, dragging, and renaming.
---@class EditorTreeList : EditorControl
---@field clip boolean
---@field dragging_node any
---@field drop_node any
---@field filter string
---@field focusable boolean
---@field focused boolean
---@field folder_icon love.Image
---@field icon_scale any
---@field next_uid number
---@field on_activate function?
---@field on_context_menu function?
---@field on_drag_end function?
---@field on_drag_move function?
---@field on_drag_outside function?
---@field on_drag_start function?
---@field on_move function?
---@field on_rename function?
---@field on_request_focus function?
---@field on_select function?
---@field on_toggle function?
---@field pending_drag any
---@field rename_input EditorTextInput
---@field rename_node any
---@field root table
---@field row_height number
---@field scroll_row number
---@field scrollbar EditorScrollbar
---@field selected_node any
---@field visible_nodes table
---@overload fun(options?: table): EditorTreeList
local EditorTreeList, super = Class(EditorControl)

local INDENT_WIDTH = 16
local ROW_HEIGHT = 26

local function isContainer(node)
    return node and node.children ~= nil
end

local function removeFromParent(node)
    if not node.parent then return end
    for index, child in ipairs(node.parent.children) do
        if child == node then
            table.remove(node.parent.children, index)
            break
        end
    end
end

local function containsNode(folder, candidate)
    local parent = candidate
    while parent do
        if parent == folder then return true end
        parent = parent.parent
    end
    return false
end

function EditorTreeList:init(options)
    options = options or {}
    super.init(self, options.x, options.y, options.width or 220, options.height or 240)
    self.row_height = options.row_height or ROW_HEIGHT
    self.on_select = options.on_select
    self.on_activate = options.on_activate
    self.on_move = options.on_move
    self.on_toggle = options.on_toggle
    self.on_rename = options.on_rename
    self.on_drag_outside = options.on_drag_outside
    self.on_drag_move = options.on_drag_move
    self.on_drag_start = options.on_drag_start
    self.on_drag_end = options.on_drag_end
    self.on_context_menu = options.on_context_menu
    self.on_request_focus = options.on_request_focus
    self.focusable = true
    self.focused = false
    self.clip = true
    self.filter = ""
    self.scroll_row = 0
    self.selected_node = nil
    self.visible_nodes = {}
    self.next_uid = 1
    self.pending_drag = nil
    self.dragging_node = nil
    self.drop_node = nil
    self.root = { type = "folder", name = "", children = {}, expanded = true, root = true }
    self.folder_icon = Assets.getTexture("editor/ui/folder")
    self.icon_scale = options.icon_scale or 2

    self.scrollbar = self:addChild(EditorScrollbar({
        width = options.scrollbar_width or 12,
        on_changed = function(value) self:setScrollValue(value) end
    }))
    self.rename_input = self:addChild(EditorTextInput({
        on_submit = function() return self:finishRename(true) end,
        on_cancel = function() self:finishRename(false) end
    }))
    self.rename_input.visible = false
    self.rename_input.onBlur = function(input)
        input.focused = false
        love.keyboard.setTextInput(false)
        if self.rename_node then self:finishRename(true, true) end
    end
end

function EditorTreeList:newNode(node_type, name, options)
    options = options or {}
    local container = node_type == "folder" or options.container == true
    local node = {
        type = node_type,
        name = tostring(name or (node_type == "folder" and "New Folder" or "New Map")),
        children = container and {} or nil,
        expanded = container and options.expanded ~= false or nil,
        registry_id = options.registry_id,
        virtual = options.virtual == true,
        badge_text = options.badge_text,
        badge_color = options.badge_color,
        data = options.data,
        icon = options.icon,
        color = options.color,
        right_icon = options.right_icon,
        right_color = options.right_color,
        right_action = options.right_action,
        right_icons = options.right_icons,
        renameable = options.renameable ~= false,
        draggable = options.draggable ~= false,
        uid = self.next_uid
    }
    self.next_uid = self.next_uid + 1
    return node
end

function EditorTreeList:createFolder(parent, name, options)
    parent = isContainer(parent) and parent or self.root
    local node = self:newNode("folder", name, options)
    node.parent = parent
    parent.expanded = true
    table.insert(parent.children, node)
    self:refreshVisibleNodes()
    self:selectNode(node)
    return node
end

function EditorTreeList:createMap(parent, name, options)
    parent = isContainer(parent) and parent or self.root
    local node = self:newNode("map", name, options)
    node.parent = parent
    parent.expanded = true
    table.insert(parent.children, node)
    self:refreshVisibleNodes()
    self:selectNode(node)
    return node
end

function EditorTreeList:clear()
    self.root.children = {}
    self.selected_node = nil
    self.scroll_row = 0
    self:finishRename(false)
    self:refreshVisibleNodes()
end

function EditorTreeList:sort(folder)
    folder = folder or self.root
    table.sort(folder.children, function(a, b)
        if a.type ~= b.type then return a.type == "folder" end
        return a.name:lower() < b.name:lower()
    end)
    for _, child in ipairs(folder.children) do
        if isContainer(child) then self:sort(child) end
    end
    self:refreshVisibleNodes()
end

function EditorTreeList:setFilter(filter)
    filter = tostring(filter or ""):lower()
    if filter == self.filter then return end
    self.filter = filter
    self.scroll_row = 0
    self:refreshVisibleNodes()
end

function EditorTreeList:nodeMatches(node)
    if self.filter == "" then return true end
    if node.name:lower():find(self.filter, 1, true) then return true end
    if isContainer(node) then
        for _, child in ipairs(node.children) do
            if self:nodeMatches(child) then return true end
        end
    end
    return false
end

function EditorTreeList:refreshVisibleNodes()
    self.visible_nodes = {}
    local function addChildren(parent, depth, ancestor_matches)
        for _, node in ipairs(parent.children) do
            local self_matches = self.filter ~= "" and node.name:lower():find(self.filter, 1, true) ~= nil
            local visible = self.filter == "" or ancestor_matches or self:nodeMatches(node)
            if visible then
                table.insert(self.visible_nodes, { node = node, depth = depth })
                if isContainer(node) and (self.filter ~= "" or node.expanded) then
                    addChildren(node, depth + 1, ancestor_matches or self_matches)
                end
            end
        end
    end
    addChildren(self.root, 0, false)
    self:clampScroll()
end

function EditorTreeList:getVisibleRows()
    return math.max(1, math.floor(self.height / self.row_height))
end

function EditorTreeList:getMaxScroll()
    return math.max(0, #self.visible_nodes - self:getVisibleRows())
end

function EditorTreeList:clampScroll()
    self.scroll_row = MathUtils.clamp(self.scroll_row, 0, self:getMaxScroll())
    local count = #self.visible_nodes
    self.scrollbar.page = count == 0 and 1 or MathUtils.clamp(self:getVisibleRows() / count, 0, 1)
    local maximum = self:getMaxScroll()
    self.scrollbar.value = maximum == 0 and 0 or self.scroll_row / maximum
end

function EditorTreeList:setScrollValue(value)
    self.scroll_row = MathUtils.round(self:getMaxScroll() * value)
    self:clampScroll()
end

function EditorTreeList:getNodeIndexAt(y)
    if y < 0 or y >= self.height then return nil end
    local first = math.floor(self.scroll_row) + 1
    local offset = -(self.scroll_row - math.floor(self.scroll_row)) * self.row_height
    local index = first + math.floor((y - offset) / self.row_height)
    if index < 1 or index > #self.visible_nodes then return nil end
    return index
end

function EditorTreeList:getVisibleIndex(node)
    for index, entry in ipairs(self.visible_nodes) do
        if entry.node == node then return index end
    end
end

function EditorTreeList:getRowY(index)
    local first = math.floor(self.scroll_row) + 1
    local offset = -(self.scroll_row - math.floor(self.scroll_row)) * self.row_height
    return offset + (index - first) * self.row_height
end

function EditorTreeList:selectNode(node)
    if node == self.root then node = nil end
    local changed = self.selected_node ~= node
    self.selected_node = node
    if node then
        local index = self:getVisibleIndex(node)
        if index then
            if index <= self.scroll_row then self.scroll_row = index - 1 end
            if index > self.scroll_row + self:getVisibleRows() then
                self.scroll_row = index - self:getVisibleRows()
            end
            self:clampScroll()
        end
    end
    if changed and self.on_select then self.on_select(node, self) end
end

function EditorTreeList:selectIndex(index)
    if #self.visible_nodes == 0 then return self:selectNode(nil) end
    index = MathUtils.clamp(index, 1, #self.visible_nodes)
    self:selectNode(self.visible_nodes[index].node)
end

function EditorTreeList:getInsertionParent()
    if not self.selected_node then return self.root end
    if isContainer(self.selected_node) then return self.selected_node end
    return self.selected_node.parent or self.root
end

function EditorTreeList:requestFocus(control)
    if self.on_request_focus then self.on_request_focus(control, self) end
end

function EditorTreeList:beginRename(node)
    node = node or self.selected_node
    if not node or node.renameable == false then return false end
    local index = node and self:getVisibleIndex(node)
    if not index then return false end
    self.rename_node = node
    self.rename_input:setValue(node.name, true)
    self.rename_input.cursor = #self.rename_input.value + 1
    self.rename_input.visible = true
    self:updateRenameBounds()
    self:requestFocus(self.rename_input)
    return true
end

function EditorTreeList:finishRename(commit, from_blur)
    local node = self.rename_node
    if not node then return false end
    local old_name = node.name
    local new_name = StringUtils.trim(tostring(self.rename_input.value or ""))
    if commit and new_name ~= "" then node.name = new_name end
    self.rename_node = nil
    self.rename_input.visible = false
    self:refreshVisibleNodes()
    if commit and node.name ~= old_name and self.on_rename then
        self.on_rename(node, old_name, node.name, self)
    end
    if not from_blur then self:requestFocus(self) end
    return true
end

function EditorTreeList:updateRenameBounds()
    if not self.rename_node then return end
    local index = self:getVisibleIndex(self.rename_node)
    if not index then return self:finishRename(true) end
    local entry = self.visible_nodes[index]
    local label_x = 8 + entry.depth * INDENT_WIDTH + 30
    local right_count = self.rename_node.right_icons and #self.rename_node.right_icons
        or self.rename_node.right_icon and 1 or 0
    local right_space = right_count * self.row_height
    self.rename_input:setBounds(label_x - 3, self:getRowY(index) + 1,
        math.max(20, self.width - self.scrollbar.width - label_x - right_space + 1), self.row_height - 2)
end

function EditorTreeList:toggleFolder(node)
    if not isContainer(node) then return false end
    node.expanded = not node.expanded
    self:refreshVisibleNodes()
    if self.on_toggle then self.on_toggle(node, node.expanded, self) end
    return true
end

function EditorTreeList:removeNode(node)
    if not node or not node.parent then return false end
    removeFromParent(node)
    if self.selected_node == node or (isContainer(node) and containsNode(node, self.selected_node)) then
        self.selected_node = nil
    end
    self:refreshVisibleNodes()
    return true
end

function EditorTreeList:moveNode(node, parent, after)
    if not node or not node.parent or not isContainer(parent) then return false end
    if node.draggable == false then return false end
    if node == parent or (isContainer(node) and containsNode(node, parent)) then return false end
    local old_parent = node.parent
    removeFromParent(node)
    node.parent = parent
    parent.expanded = true
    local inserted = false
    if after and after.parent == parent then
        for index, child in ipairs(parent.children) do
            if child == after then
                table.insert(parent.children, index + 1, node)
                inserted = true
                break
            end
        end
    end
    if not inserted then table.insert(parent.children, node) end
    self:refreshVisibleNodes()
    self:selectNode(node)
    if self.on_move then self.on_move(node, old_parent, parent, after, self) end
    return true
end

function EditorTreeList:getDropPlacement(x, y, node)
    if x < 0 or y < 0 or x >= self.width - self.scrollbar.width or y >= self.height then return nil end
    local index = self:getNodeIndexAt(y)
    local target = index and self.visible_nodes[index].node or nil
    if target == node then return nil end
    local parent, after
    if not target then
        parent = self.root
    elseif isContainer(target) then
        parent = target
    else
        parent, after = target.parent or self.root, target
    end
    if isContainer(node) and containsNode(node, parent) then return nil end
    return parent, after, target
end

function EditorTreeList:getCursorType(x, y)
    if self.dragging_node then return "grab" end
    if x >= self.width - self.scrollbar.width then return "select" end
    return self:getNodeIndexAt(y) and "select" or "default"
end

function EditorTreeList:onFocus() self.focused = true end
function EditorTreeList:onBlur() self.focused = false end

function EditorTreeList:onMousePressed(x, y, button, presses)
    if x >= self.width - self.scrollbar.width then return false end
    local index = self:getNodeIndexAt(y)
    if button == 2 then
        local node = index and self.visible_nodes[index].node or nil
        self:selectNode(node)
        if self.on_context_menu then self.on_context_menu(node, self, x, y) end
        return self.on_context_menu ~= nil
    end
    if button ~= 1 then return false end
    if not index then
        self:selectNode(nil)
        return true
    end
    local entry = self.visible_nodes[index]
    local node = entry.node
    local already_selected = self.selected_node == node
    self:selectNode(node)
    if already_selected and self.on_select then self.on_select(node, self) end
    local disclosure_x = 5 + entry.depth * INDENT_WIDTH
    if isContainer(node) and x >= disclosure_x and x < disclosure_x + 13 then
        self:toggleFolder(node)
        return true
    end
    local right_icons = node.right_icons or (node.right_icon and {
        { icon = node.right_icon, color = node.right_color, action = node.right_action }
    }) or {}
    local icon_right = self.width - self.scrollbar.width - 6
    for index = #right_icons, 1, -1 do
        local item = right_icons[index]
        local texture = item.icon and Assets.getTexture(item.icon)
        local icon_width = texture and texture:getWidth() * self.icon_scale or self.row_height
        if x >= icon_right - icon_width and x <= icon_right then
            if item.action then item.action(node, self) end
            return item.action ~= nil
        end
        icon_right = icon_right - self.row_height
    end
    if presses and presses >= 2 then
        if isContainer(node) then
            self:toggleFolder(node)
        elseif self.on_activate then
            self.on_activate(node, self)
        end
        return true
    end
    if node.draggable ~= false then self.pending_drag = { node = node, x = x, y = y } end
    return true
end

function EditorTreeList:onMouseMoved(x, y, dx, dy)
    if self.pending_drag and not self.dragging_node
        and math.abs(x - self.pending_drag.x) + math.abs(y - self.pending_drag.y) >= 5 then
        self.dragging_node = self.pending_drag.node
        if self.on_drag_start then self.on_drag_start(self.dragging_node, self) end
    end
    if self.dragging_node then
        local _, _, target = self:getDropPlacement(x, y, self.dragging_node)
        self.drop_node = target
        if self.on_drag_move then self.on_drag_move(self.dragging_node, self, x, y) end
        return true
    end
    return false
end

function EditorTreeList:onMouseReleased(x, y, button)
    if button ~= 1 then return false end
    local node = self.dragging_node
    self.pending_drag = nil
    self.dragging_node = nil
    self.drop_node = nil
    if not node then return false end
    local parent, after = self:getDropPlacement(x, y, node)
    if parent then
        self:moveNode(node, parent, after)
    elseif self.on_drag_outside then
        self.on_drag_outside(node, self, x, y)
    end
    if self.on_drag_end then self.on_drag_end(node, self, x, y) end
    return true
end

function EditorTreeList:onWheelMoved(_, y)
    self.scroll_row = self.scroll_row - y * 3
    self:clampScroll()
    return true
end

function EditorTreeList:onKeyPressed(key)
    local index = self:getVisibleIndex(self.selected_node)
    if key == "up" then
        self:selectIndex((index or 2) - 1)
        return true
    elseif key == "down" then
        self:selectIndex((index or 0) + 1)
        return true
    elseif key == "left" and self.selected_node then
        if isContainer(self.selected_node) and self.selected_node.expanded then
            self:toggleFolder(self.selected_node)
        elseif self.selected_node.parent and self.selected_node.parent ~= self.root then
            self:selectNode(self.selected_node.parent)
        end
        return true
    elseif key == "right" and isContainer(self.selected_node) then
        if not self.selected_node.expanded then self:toggleFolder(self.selected_node) end
        return true
    elseif key == "return" or key == "kpenter" then
        if self.selected_node then
            if isContainer(self.selected_node) then
                self:toggleFolder(self.selected_node)
            elseif self.on_activate then
                self.on_activate(self.selected_node, self)
            end
        end
        return true
    elseif key == "f2" then
        return self:beginRename()
    end
    return false
end

function EditorTreeList:update(dt)
    self.scrollbar:setBounds(self.width - self.scrollbar.width, 0, self.scrollbar.width, self.height)
    self:clampScroll()
    self:updateRenameBounds()
    super.update(self, dt)
end

function EditorTreeList:drawSelf()
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local first = math.floor(self.scroll_row) + 1
    local last = math.min(#self.visible_nodes, first + self:getVisibleRows())
    for index = first, last do
        local entry = self.visible_nodes[index]
        local node = entry.node
        local y = self:getRowY(index)
        if node == self.drop_node then
            Draw.setColor(0.28, 0.48, 0.82, 0.35)
            love.graphics.rectangle("fill", 0, y, self.width - self.scrollbar.width, self.row_height)
        elseif node == self.selected_node then
            Draw.setColor(self.focused and 0.22 or 0.17, self.focused and 0.34 or 0.22,
                self.focused and 0.52 or 0.30, 1)
            love.graphics.rectangle("fill", 0, y, self.width - self.scrollbar.width, self.row_height)
        end

        local disclosure_x = 5 + entry.depth * INDENT_WIDTH
        if isContainer(node) then
            Draw.setColor(0.72, 0.72, 0.76, 1)
            if node.expanded then
                love.graphics.polygon("fill", disclosure_x + 1, y + 10, disclosure_x + 10, y + 10,
                    disclosure_x + 5.5, y + 16)
            else
                love.graphics.polygon("fill", disclosure_x + 2, y + 8, disclosure_x + 8, y + 13,
                    disclosure_x + 2, y + 18)
            end
            local icon = node.icon and Assets.getTexture(node.icon) or self.folder_icon
            if icon then
                local scale = self.icon_scale
                Draw.setColor(node.color or { 1, 1, 1, 1 })
                Draw.draw(icon, disclosure_x + 13,
                    math.floor(y + (self.row_height - icon:getHeight() * scale) / 2), 0, scale, scale)
            end
        elseif node.icon then
            local icon = Assets.getTexture(node.icon)
            local scale = self.icon_scale
            if icon then
                Draw.setColor(node.color or { 1, 1, 1, 1 })
                Draw.draw(icon, disclosure_x + 13,
                    math.floor(y + (self.row_height - icon:getHeight() * scale) / 2), 0, scale, scale)
            end
        end

        if node ~= self.rename_node then
            local label_x = 8 + entry.depth * INDENT_WIDTH + 30
            Draw.setColor(node.virtual and 0.62 or 0.88, node.virtual and 0.75 or 0.88,
                node.virtual and 0.92 or 0.90, 1)
            love.graphics.print(node.name, label_x, math.floor(y + (self.row_height - font:getHeight()) / 2))
            if node.badge_text then
                Draw.setColor(node.badge_color or { 1, 1, 1, 1 })
                love.graphics.print(node.badge_text, label_x + font:getWidth(node.name) + 4,
                    math.floor(y + (self.row_height - font:getHeight()) / 2))
            end
        end
        local right_icons = node.right_icons or (node.right_icon and {
            { icon = node.right_icon, color = node.right_color }
        }) or {}
        local icon_right = self.width - self.scrollbar.width - 6
        for icon_index = #right_icons, 1, -1 do
            local item = right_icons[icon_index]
            local texture = item.icon and Assets.getTexture(item.icon)
            local scale = self.icon_scale
            if texture then
                local icon_x = icon_right - texture:getWidth() * scale
                local icon_y = math.floor(y + (self.row_height - texture:getHeight() * scale) / 2)
                Draw.setColor(item.color or { 0.82, 0.82, 0.85, 1 })
                Draw.draw(texture, icon_x, icon_y, 0, scale, scale)
            end
            icon_right = icon_right - self.row_height
        end
    end
end

return EditorTreeList
