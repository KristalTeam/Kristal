---@class EditorDockSpace : Class
---@overload fun(): EditorDockSpace
local EditorDockSpace = Class()

local REGIONS = { "top", "bottom", "left", "right", "center" }
local HEADER_HEIGHT = 28
local SPLITTER_SIZE = 5
local EDGE_TARGET_SIZE = 64
local FLOATING_RESIZE_SIZE = 6

local pointInRect = MathUtils.pointInRect

local function copyRect(rect)
    return { x = rect.x, y = rect.y, width = rect.width, height = rect.height }
end

local function withScissor(rect, callback)
    local old_scissor = { love.graphics.getScissor() }
    local x1, y1 = love.graphics.transformPoint(rect.x, rect.y)
    local x2, y2 = love.graphics.transformPoint(rect.x + rect.width, rect.y + rect.height)
    local x, y = math.min(x1, x2), math.min(y1, y2)
    local width, height = math.abs(x2 - x1), math.abs(y2 - y1)
    if old_scissor[1] then
        love.graphics.intersectScissor(x, y, width, height)
    else
        love.graphics.setScissor(x, y, width, height)
    end
    callback()
    love.graphics.setScissor(unpack(old_scissor))
end

function EditorDockSpace:init()
    self.x, self.y, self.width, self.height = 0, 0, 0, 0
    self.panels = {}
    self.panel_order = {}
    self.stacks = {}
    self.region_stacks = {}
    self.stack_serial = 0
    for _, region in ipairs(REGIONS) do
        local stack = EditorDockStack(region, region)
        self.stacks[region] = stack
        self.region_stacks[region] = { stack }
    end
    self.sizes = { top = 180, bottom = 180, left = 260, right = 260 }
    self.minimum_center_width = 160
    self.minimum_center_height = 120
    self.floating = {}
    self.focused_control = nil
    self.captured_control = nil
    self.pending_drag = nil
    self.dragging_panel = nil
    self.drag_offset_x = 0
    self.drag_offset_y = 0
    self.dock_preview = nil
    self.splitter_drag = nil
    self.floating_resize = nil
    self.context_menu = nil
    self.splitters = {}
    self.theme = {
        workspace = { 0.055, 0.055, 0.065, 1 },
        panel = { 0.105, 0.105, 0.12, 1 },
        header = { 0.14, 0.14, 0.16, 1 },
        tab_active = { 0.22, 0.22, 0.25, 1 },
        tab_inactive = { 0.13, 0.13, 0.15, 1 },
        border = { 0.30, 0.30, 0.34, 1 },
        text = { 0.90, 0.90, 0.92, 1 },
        preview = { 0.28, 0.48, 0.82, 0.38 }
    }
end

function EditorDockSpace:getStacks()
    local result = {}
    for _, region in ipairs(REGIONS) do
        for _, stack in ipairs(self.region_stacks[region]) do table.insert(result, stack) end
    end
    return result
end

function EditorDockSpace:createStack(region, id, index)
    self.stack_serial = self.stack_serial + 1
    id = id or (region .. ":split:" .. self.stack_serial)
    while self.stacks[id] do
        self.stack_serial = self.stack_serial + 1
        id = region .. ":split:" .. self.stack_serial
    end
    local stack = EditorDockStack(id, region)
    self.stacks[id] = stack
    table.insert(self.region_stacks[region], index or (#self.region_stacks[region] + 1), stack)
    return stack
end

function EditorDockSpace:removeEmptySplitStacks()
    for _, region in ipairs(REGIONS) do
        local stacks = self.region_stacks[region]
        for index = #stacks, 2, -1 do
            if stacks[index]:isEmpty() then
                self.stacks[stacks[index].id] = nil
                table.remove(stacks, index)
            end
        end
    end
end

function EditorDockSpace:setBounds(x, y, width, height)
    self.x, self.y = x, y
    self.width, self.height = math.max(0, width), math.max(0, height)
    self:layout()
end

function EditorDockSpace:registerPanel(panel, region)
    assert(not self.panels[panel.id], "Duplicate editor panel id: " .. panel.id)
    self.panels[panel.id] = panel
    table.insert(self.panel_order, panel)
    if panel.visible then
        self:dockPanel(panel, region or "center")
    else
        panel.last_region = region or "center"
    end
    return panel
end

function EditorDockSpace:setPanelVisible(panel, visible, region)
    if type(panel) == "string" then panel = self.panels[panel] end
    if not panel or panel.visible == visible then return false end
    panel.visible = visible
    if visible then
        self:dockPanel(panel, region or panel.last_region or "center")
    else
        if panel.stack then
            panel.last_region = panel.stack.id
            panel.stack:removePanel(panel)
        end
        self:removeFloating(panel)
        self:removeEmptySplitStacks()
        self:layout()
    end
    if panel.on_visibility_changed then panel.on_visibility_changed(panel, visible) end
    return true
end

function EditorDockSpace:unregisterPanel(panel)
    if type(panel) == "string" then panel = self.panels[panel] end
    if not panel then return false end
    if panel.stack then panel.stack:removePanel(panel) end
    self:removeFloating(panel)
    self.panels[panel.id] = nil
    for index, candidate in ipairs(self.panel_order) do
        if candidate == panel then table.remove(self.panel_order, index) break end
    end
    panel.visible = false
    self:removeEmptySplitStacks()
    self:layout()
    return true
end

function EditorDockSpace:dockPanel(panel, target)
    if type(target) == "string" then
        target = self.stacks[target] or self.stacks[target:match("^[^:]+")]
    end
    assert(target, "Unknown editor dock target")
    self:removeFloating(panel)
    panel.last_region = target.id
    target:addPanel(panel)
    self:removeEmptySplitStacks()
    self:layout()
end

function EditorDockSpace:dockPanelSplit(panel, target, side)
    local stacks = self.region_stacks[target.region]
    local target_index = 1
    for index, stack in ipairs(stacks) do
        if stack == target then target_index = index break end
    end
    local insert_index = (side == "top" or side == "left") and target_index or target_index + 1
    self:removeFloating(panel)
    local stack = self:createStack(target.region, nil, insert_index)
    panel.last_region = stack.id
    stack:addPanel(panel)
    self:removeEmptySplitStacks()
    self:layout()
end

function EditorDockSpace:floatPanel(panel, rect)
    if panel.stack then panel.stack:removePanel(panel) end
    self:removeFloating(panel)
    panel.floating = rect or {
        x = self.x + 80,
        y = self.y + 80,
        width = panel.preferred_width,
        height = panel.preferred_height
    }
    table.insert(self.floating, panel)
    self:removeEmptySplitStacks()
    self:layout()
end

function EditorDockSpace:removeFloating(panel)
    for index, candidate in ipairs(self.floating) do
        if candidate == panel then table.remove(self.floating, index) break end
    end
    panel.floating = nil
end

function EditorDockSpace:setFocus(control)
    if self.focused_control == control then return end
    if self.focused_control then self.focused_control:onBlur() end
    self.focused_control = control
    if control and control.focusable then control:onFocus() end
end

function EditorDockSpace:getVisibleSize(region)
    for _, stack in ipairs(self.region_stacks[region]) do
        if not stack:isEmpty() then return self.sizes[region] end
    end
    return 0
end

function EditorDockSpace:layoutRegion(region, rect)
    local visible = {}
    for _, stack in ipairs(self.region_stacks[region]) do
        if not stack:isEmpty() then table.insert(visible, stack) end
    end
    if #visible == 0 then
        local stack = self.stacks[region]
        stack.x, stack.y, stack.width, stack.height = rect.x, rect.y, rect.width, rect.height
        stack.tab_rects = {}
        return
    end
    local horizontal = region == "top" or region == "bottom"
    local gap = #visible > 1 and SPLITTER_SIZE or 0
    local cursor = horizontal and rect.x or rect.y
    local finish = cursor + (horizontal and rect.width or rect.height)
    for index, stack in ipairs(visible) do
        local remaining = #visible - index + 1
        local size = index == #visible and (finish - cursor)
            or math.floor((finish - cursor - gap * (remaining - 1)) / remaining)
        if horizontal then
            stack.x, stack.y, stack.width, stack.height = cursor, rect.y, math.max(0, size), rect.height
        else
            stack.x, stack.y, stack.width, stack.height = rect.x, cursor, rect.width, math.max(0, size)
        end
        self:layoutStackContent(stack)
        cursor = cursor + size + gap
    end
end

function EditorDockSpace:layout()
    local top = math.min(self:getVisibleSize("top"), math.max(0, self.height - self.minimum_center_height))
    local bottom = math.min(self:getVisibleSize("bottom"), math.max(0, self.height - top - self.minimum_center_height))
    local middle_y = self.y + top + (top > 0 and SPLITTER_SIZE or 0)
    local middle_h = self.height - top - bottom
        - (top > 0 and SPLITTER_SIZE or 0) - (bottom > 0 and SPLITTER_SIZE or 0)
    local left = math.min(self:getVisibleSize("left"), math.max(0, self.width - self.minimum_center_width))
    local right = math.min(self:getVisibleSize("right"), math.max(0, self.width - left - self.minimum_center_width))
    local middle_x = self.x + left + (left > 0 and SPLITTER_SIZE or 0)
    local middle_w = self.width - left - right
        - (left > 0 and SPLITTER_SIZE or 0) - (right > 0 and SPLITTER_SIZE or 0)

    local rects = {
        top = { x = self.x, y = self.y, width = self.width, height = top },
        bottom = { x = self.x, y = self.y + self.height - bottom, width = self.width, height = bottom },
        left = { x = self.x, y = middle_y, width = left, height = middle_h },
        right = { x = self.x + self.width - right, y = middle_y, width = right, height = middle_h },
        center = { x = middle_x, y = middle_y, width = math.max(0, middle_w), height = math.max(0, middle_h) }
    }
    for region, rect in pairs(rects) do self:layoutRegion(region, rect) end
    self.splitters = {}
    if top > 0 then self.splitters.top = { x = self.x, y = self.y + top, width = self.width, height = SPLITTER_SIZE } end
    if bottom > 0 then self.splitters.bottom = { x = self.x, y = self.y + self.height - bottom - SPLITTER_SIZE, width = self.width, height = SPLITTER_SIZE } end
    if left > 0 then self.splitters.left = { x = self.x + left, y = middle_y, width = SPLITTER_SIZE, height = middle_h } end
    if right > 0 then self.splitters.right = { x = self.x + self.width - right - SPLITTER_SIZE, y = middle_y, width = SPLITTER_SIZE, height = middle_h } end

    for _, panel in ipairs(self.floating) do
        panel.floating.width = math.max(panel.minimum_width, panel.floating.width)
        panel.floating.height = math.max(panel.minimum_height + HEADER_HEIGHT, panel.floating.height)
        self:layoutPanelContent(panel, panel.floating)
    end
end

function EditorDockSpace:layoutStackContent(stack)
    stack.tab_rects = {}
    if stack:isEmpty() then return end
    local font = EditorFont.get(16)
    local tab_x = stack.x
    for index, panel in ipairs(stack.panels) do
        local width = math.min(math.max(72, font:getWidth(panel.title) + 20), math.max(72, stack.width))
        stack.tab_rects[index] = { x = tab_x, y = stack.y, width = width, height = HEADER_HEIGHT }
        tab_x = tab_x + width
    end
    self:layoutPanelContent(stack:getActivePanel(), {
        x = stack.x, y = stack.y, width = stack.width, height = stack.height
    })
end

function EditorDockSpace:layoutPanelContent(panel, rect)
    if not panel or not panel.content then return end
    local content_x, content_y = rect.x, rect.y + HEADER_HEIGHT
    local content_width, content_height = rect.width, math.max(0, rect.height - HEADER_HEIGHT)
    if panel.fixed_content_width then
        content_x = content_x + math.max(0, (content_width - panel.fixed_content_width) / 2)
        content_width = panel.fixed_content_width
    end
    if panel.fixed_content_height then
        content_y = content_y + math.max(0, (content_height - panel.fixed_content_height) / 2)
        content_height = panel.fixed_content_height
    end
    panel.content:setBounds(content_x, content_y, content_width, content_height)
end

function EditorDockSpace:getPanelContentRect(rect)
    return {
        x = rect.x,
        y = rect.y + HEADER_HEIGHT,
        width = rect.width,
        height = math.max(0, rect.height - HEADER_HEIGHT)
    }
end

function EditorDockSpace:drawPanelContent(panel, rect)
    if not panel or not panel.content then return end
    withScissor(self:getPanelContentRect(rect), function()
        panel.content:draw()
    end)
end

function EditorDockSpace:update(dt)
    self:layout()
    for _, stack in ipairs(self:getStacks()) do
        local panel = stack:getActivePanel()
        if panel and panel.content then panel.content:update(dt) end
    end
    for _, panel in ipairs(self.floating) do
        if panel.content then panel.content:update(dt) end
    end
end

function EditorDockSpace:drawStack(stack)
    if stack:isEmpty() or stack.width <= 0 or stack.height <= 0 then return end
    love.graphics.setColor(self.theme.panel)
    love.graphics.rectangle("fill", stack.x, stack.y, stack.width, stack.height)
    for index, panel in ipairs(stack.panels) do
        local rect = stack.tab_rects[index]
        love.graphics.setColor(index == stack.active_index and self.theme.tab_active or self.theme.tab_inactive)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(self.theme.border)
        love.graphics.rectangle("line", rect.x + 0.5, rect.y + 0.5, rect.width - 1, rect.height - 1)
        love.graphics.setColor(self.theme.text)
        love.graphics.setFont(EditorFont.get(16))
        love.graphics.print(panel.title, rect.x + 10, rect.y + math.floor((HEADER_HEIGHT - EditorFont.get(16):getHeight()) / 2))
    end
    local panel = stack:getActivePanel()
    self:drawPanelContent(panel, {
        x = stack.x, y = stack.y, width = stack.width, height = stack.height
    })
    love.graphics.setLineWidth(1)
    love.graphics.setColor(self.theme.border)
    love.graphics.rectangle("line", stack.x + 0.5, stack.y + 0.5, stack.width - 1, stack.height - 1)
end

function EditorDockSpace:drawFloating(panel)
    local rect = panel.floating
    love.graphics.setColor(self.theme.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
    love.graphics.setColor(self.theme.header)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, HEADER_HEIGHT)
    love.graphics.setColor(self.theme.text)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    love.graphics.print(panel.title, rect.x + 10, rect.y + math.floor((HEADER_HEIGHT - font:getHeight()) / 2))
    self:drawPanelContent(panel, rect)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(self.theme.border)
    love.graphics.rectangle("line", rect.x + 0.5, rect.y + 0.5, rect.width - 1, rect.height - 1)
end

function EditorDockSpace:draw()
    love.graphics.setColor(self.theme.workspace)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    for _, stack in ipairs(self:getStacks()) do self:drawStack(stack) end
    for _, panel in ipairs(self.floating) do self:drawFloating(panel) end
    if self.dock_preview then
        love.graphics.setColor(self.theme.preview)
        love.graphics.rectangle("fill", self.dock_preview.rect.x, self.dock_preview.rect.y,
            self.dock_preview.rect.width, self.dock_preview.rect.height)
    end
    self:drawContextMenu()
end

function EditorDockSpace:getPanelAt(x, y)
    for index = #self.floating, 1, -1 do
        local panel = self.floating[index]
        if pointInRect(x, y, panel.floating) then return panel, panel.floating end
    end
    for _, stack in ipairs(self:getStacks()) do
        local rect = { x = stack.x, y = stack.y, width = stack.width, height = stack.height }
        if not stack:isEmpty() and pointInRect(x, y, rect) then return stack:getActivePanel(), rect, stack end
    end
end

function EditorDockSpace:getTabAt(x, y)
    for index = #self.floating, 1, -1 do
        local panel = self.floating[index]
        local rect = { x = panel.floating.x, y = panel.floating.y, width = panel.floating.width, height = HEADER_HEIGHT }
        if pointInRect(x, y, rect) then return panel, rect end
    end
    for _, stack in ipairs(self:getStacks()) do
        for index, rect in ipairs(stack.tab_rects) do
            if pointInRect(x, y, rect) then return stack.panels[index], rect, stack end
        end
    end
end

function EditorDockSpace:getControlAt(x, y)
    for index = #self.floating, 1, -1 do
        local panel = self.floating[index]
        if panel.content and pointInRect(x, y, self:getPanelContentRect(panel.floating)) then
            local target = panel.content:getControlAt(x, y)
            if target then return target end
        end
    end
    for _, stack in ipairs(self:getStacks()) do
        local panel = stack:getActivePanel()
        local rect = { x = stack.x, y = stack.y, width = stack.width, height = stack.height }
        if panel and panel.content and pointInRect(x, y, self:getPanelContentRect(rect)) then
            local target = panel.content:getControlAt(x, y)
            if target then return target end
        end
    end
end

function EditorDockSpace:getSplitterAt(x, y)
    for region, rect in pairs(self.splitters) do
        if pointInRect(x, y, rect) then return region end
    end
end

function EditorDockSpace:getFloatingResizeAt(x, y)
    for index = #self.floating, 1, -1 do
        local panel = self.floating[index]
        local rect = panel.floating
        if x >= rect.x - FLOATING_RESIZE_SIZE and x <= rect.x + rect.width + FLOATING_RESIZE_SIZE
            and y >= rect.y - FLOATING_RESIZE_SIZE and y <= rect.y + rect.height + FLOATING_RESIZE_SIZE then
            local edges = {
                left = math.abs(x - rect.x) <= FLOATING_RESIZE_SIZE,
                right = math.abs(x - (rect.x + rect.width)) <= FLOATING_RESIZE_SIZE,
                top = math.abs(y - rect.y) <= FLOATING_RESIZE_SIZE,
                bottom = math.abs(y - (rect.y + rect.height)) <= FLOATING_RESIZE_SIZE
            }
            if edges.left or edges.right or edges.top or edges.bottom then
                local cursor_type
                if (edges.left and edges.top) or (edges.right and edges.bottom) then
                    cursor_type = "resize_diag_l"
                elseif (edges.right and edges.top) or (edges.left and edges.bottom) then
                    cursor_type = "resize_diag_r"
                elseif edges.left or edges.right then
                    cursor_type = "resize_hori"
                else
                    cursor_type = "resize_vert"
                end
                return panel, edges, cursor_type
            end
            return
        end
    end
end

function EditorDockSpace:getSplitterCursor(region)
    return (region == "left" or region == "right") and "resize_hori" or "resize_vert"
end

function EditorDockSpace:getCursorType(x, y)
    if self.floating_resize then return self.floating_resize.cursor_type end
    if self.splitter_drag then return self:getSplitterCursor(self.splitter_drag.region) end
    if self.dragging_panel or self.pending_drag then return "resize_all" end
    if self.context_menu then
        self:updateContextMenuHover(x, y)
        if pointInRect(x, y, self.context_menu.rect)
            or (self.context_menu.submenu_rect and pointInRect(x, y, self.context_menu.submenu_rect)) then
            return "select"
        end
    end

    if self.captured_control and self.captured_control.getCursorType then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        return self.captured_control:getCursorType(local_x, local_y)
    end

    local _, _, floating_cursor = self:getFloatingResizeAt(x, y)
    if floating_cursor then return floating_cursor end
    local splitter = self:getSplitterAt(x, y)
    if splitter then return self:getSplitterCursor(splitter) end
    if self:getTabAt(x, y) then return "resize_all" end

    local target = self:getControlAt(x, y)
    if target then
        if target.getCursorType then
            local local_x, local_y = target:toLocal(x, y)
            return target:getCursorType(local_x, local_y)
        end
        if target.cursor_type then return target.cursor_type end
    end
    return "default"
end

function EditorDockSpace:getPanelRect(panel)
    if panel.floating then return copyRect(panel.floating) end
    if panel.stack then
        return { x = panel.stack.x, y = panel.stack.y, width = panel.stack.width, height = panel.stack.height }
    end
end

function EditorDockSpace:isPanelDisplayed(panel)
    return panel and panel.visible
        and (panel.floating ~= nil or (panel.stack and panel.stack:getActivePanel() == panel))
end

function EditorDockSpace:undockPanel(panel, source_rect)
    source_rect = source_rect or self:getPanelRect(panel) or {
        x = self.x + 40,
        y = self.y + 40
    }
    local width = math.min(self.width, math.max(panel.minimum_width, panel.preferred_width))
    local height = math.min(self.height, math.max(panel.minimum_height + HEADER_HEIGHT, panel.preferred_height))
    local x = MathUtils.clamp(source_rect.x, self.x, math.max(self.x, self.x + self.width - width))
    local y = MathUtils.clamp(source_rect.y, self.y, math.max(self.y, self.y + self.height - height))
    self:floatPanel(panel, { x = x, y = y, width = width, height = height })
end

function EditorDockSpace:openPanelContextMenu(panel, x, y)
    local source_rect = self:getPanelRect(panel)
    local items = {}
    if panel.stack then
        table.insert(items, {
            label = "Undock",
            action = function() self:undockPanel(panel, source_rect) end
        })
    end
    local dock_items = {}
    local region_labels = { center = "Center", left = "Left", right = "Right", top = "Top", bottom = "Bottom" }
    for _, region in ipairs({ "center", "left", "right", "top", "bottom" }) do
        local target_region = region
        table.insert(dock_items, {
            label = region_labels[target_region],
            action = function() self:dockPanel(panel, target_region) end
        })
    end
    table.insert(items, { label = "Dock", children = dock_items })
    table.insert(items, {
        label = panel.recoverable and "Close Panel" or "Remove Panel",
        action = function() self:closePanelFromContext(panel) end
    })

    self:openContextMenu(items, x, y, panel)
    self.context_menu.panel = panel
end

function EditorDockSpace:openContextMenu(items, x, y, owner)
    if not items or #items == 0 then return false end
    local font = EditorFont.get(16)
    local width = 140
    for _, item in ipairs(items) do width = math.max(width, font:getWidth(item.label) + (item.checked and 38 or 24)) end
    local height = #items * 28
    local menu_x = MathUtils.clamp(x, self.x, math.max(self.x, self.x + self.width - width))
    local menu_y = MathUtils.clamp(y, self.y, math.max(self.y, self.y + self.height - height))
    for index, item in ipairs(items) do
        item.rect = { x = menu_x, y = menu_y + (index - 1) * 28, width = width, height = 28 }
    end
    self.context_menu = {
        owner = owner,
        items = items,
        rect = { x = menu_x, y = menu_y, width = width, height = height },
        submenu = nil,
        submenu_rect = nil
    }
    return true
end

function EditorDockSpace:openContextSubmenu(menu, item)
    if menu.submenu == item then return end
    local font = EditorFont.get(16)
    local width = 120
    for _, child in ipairs(item.children) do
        width = math.max(width, font:getWidth(child.label) + (child.checked and 38 or 24))
    end
    local height = #item.children * 28
    local x = menu.rect.x + menu.rect.width
    if x + width > self.x + self.width then x = menu.rect.x - width end
    local y = MathUtils.clamp(item.rect.y, self.y, math.max(self.y, self.y + self.height - height))
    for index, child in ipairs(item.children) do
        child.rect = { x = x, y = y + (index - 1) * 28, width = width, height = 28 }
    end
    menu.submenu = item
    menu.submenu_rect = { x = x, y = y, width = width, height = height }
end

function EditorDockSpace:updateContextMenuHover(x, y)
    local menu = self.context_menu
    if not menu then return end
    for _, item in ipairs(menu.items) do
        if pointInRect(x, y, item.rect) then
            if item.children then
                self:openContextSubmenu(menu, item)
            elseif not (menu.submenu_rect and pointInRect(x, y, menu.submenu_rect)) then
                menu.submenu = nil
                menu.submenu_rect = nil
            end
            return
        end
    end
    if menu.submenu_rect and pointInRect(x, y, menu.submenu_rect) then return end
    menu.submenu = nil
    menu.submenu_rect = nil
end

function EditorDockSpace:getContextMenuItemAt(x, y)
    local menu = self.context_menu
    if not menu then return nil end
    self:updateContextMenuHover(x, y)
    if menu.submenu then
        for _, item in ipairs(menu.submenu.children) do
            if pointInRect(x, y, item.rect) then return item end
        end
    end
    for _, item in ipairs(menu.items) do
        if pointInRect(x, y, item.rect) then return item end
    end
end

function EditorDockSpace:closePanelFromContext(panel)
    if panel.recoverable then
        self:setPanelVisible(panel, false)
    elseif panel.on_remove then
        panel.on_remove(panel)
    else
        self:unregisterPanel(panel)
    end
end

function EditorDockSpace:drawContextMenu()
    local menu = self.context_menu
    if not menu then return end
    love.graphics.setLineWidth(1)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    local mouse_x, mouse_y = love.mouse.getPosition()
    self:updateContextMenuHover(mouse_x, mouse_y)
    for _, item in ipairs(menu.items) do
        local rect = item.rect
        love.graphics.setColor(pointInRect(mouse_x, mouse_y, rect)
            and self.theme.tab_active or self.theme.tab_inactive)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
        love.graphics.setColor(self.theme.text)
        if item.checked then love.graphics.print("*", rect.x + 8,
            rect.y + math.floor((rect.height - font:getHeight()) / 2)) end
        love.graphics.print(item.label, rect.x + (item.checked and 24 or 12),
            rect.y + math.floor((rect.height - font:getHeight()) / 2))
        if item.children then
            love.graphics.print(">", rect.x + rect.width - font:getWidth(">") - 10,
                rect.y + math.floor((rect.height - font:getHeight()) / 2))
        end
    end
    local rect = menu.rect
    love.graphics.setColor(self.theme.border)
    love.graphics.rectangle("line", rect.x + 0.5, rect.y + 0.5, rect.width - 1, rect.height - 1)
    if menu.submenu then
        for _, item in ipairs(menu.submenu.children) do
            local item_rect = item.rect
            love.graphics.setColor(pointInRect(mouse_x, mouse_y, item_rect)
                and self.theme.tab_active or self.theme.tab_inactive)
            love.graphics.rectangle("fill", item_rect.x, item_rect.y, item_rect.width, item_rect.height)
            love.graphics.setColor(self.theme.text)
            if item.checked then love.graphics.print("*", item_rect.x + 8,
                item_rect.y + math.floor((item_rect.height - font:getHeight()) / 2)) end
            love.graphics.print(item.label, item_rect.x + (item.checked and 24 or 12),
                item_rect.y + math.floor((item_rect.height - font:getHeight()) / 2))
        end
        local submenu_rect = menu.submenu_rect
        love.graphics.setColor(self.theme.border)
        love.graphics.rectangle("line", submenu_rect.x + 0.5, submenu_rect.y + 0.5,
            submenu_rect.width - 1, submenu_rect.height - 1)
    end
end

function EditorDockSpace:getStackHeaderRect(stack)
    if type(stack) == "string" then stack = self.stacks[stack] end
    if not stack or stack:isEmpty() then return nil end
    return { x = stack.x, y = stack.y, width = stack.width, height = HEADER_HEIGHT }
end

function EditorDockSpace:isPointInStackHeader(stack, x, y)
    if type(stack) == "string" and self.region_stacks[stack] then
        for _, candidate in ipairs(self.region_stacks[stack]) do
            if pointInRect(x, y, self:getStackHeaderRect(candidate)) then return true end
        end
        return false
    end
    return pointInRect(x, y, self:getStackHeaderRect(stack))
end

function EditorDockSpace:onMousePressed(x, y, button, presses)
    if self.context_menu then
        local menu = self.context_menu
        if button == 1 then
            local item = self:getContextMenuItemAt(x, y)
            if item and item.children then
                self:openContextSubmenu(menu, item)
                return true
            elseif item and item.action then
                self.context_menu = nil
                item.action()
                return true
            end
        end
        self.context_menu = nil
        if button == 1 then return true end
    end
    if button == 2 then
        local panel = self:getTabAt(x, y)
        if panel then
            self:openPanelContextMenu(panel, x, y)
            return true
        end
    end
    if button == 1 then
        local resizing_panel, resize_edges, resize_cursor = self:getFloatingResizeAt(x, y)
        if resizing_panel then
            local rect = resizing_panel.floating
            self.floating_resize = {
                panel = resizing_panel,
                edges = resize_edges,
                cursor_type = resize_cursor,
                start_x = x,
                start_y = y,
                rect = copyRect(rect)
            }
            return true
        end
        local splitter = self:getSplitterAt(x, y)
        if splitter then
            self.splitter_drag = { region = splitter, start_x = x, start_y = y, start_size = self.sizes[splitter] }
            return true
        end
        local panel, rect, stack = self:getTabAt(x, y)
        if panel then
            if stack then
                stack:setActivePanel(panel, true)
            elseif panel.on_activate then
                panel.on_activate(panel)
            end
            self.pending_drag = { panel = panel, rect = copyRect(rect), start_x = x, start_y = y,
                offset_x = x - rect.x, offset_y = y - rect.y }
            return true
        end
    end
    local target = self:getControlAt(x, y)
    if target then
        if target.focusable then self:setFocus(target) elseif self.focused_control then self:setFocus(nil) end
        local local_x, local_y = target:toLocal(x, y)
        if target:onMousePressed(local_x, local_y, button, presses) then
            self.captured_control = target
            return true
        end
    elseif button == 1 then
        self:setFocus(nil)
    end
    return false
end

function EditorDockSpace:onMouseMoved(x, y, dx, dy)
    if self.floating_resize then
        local resize = self.floating_resize
        local panel = resize.panel
        local rect = panel.floating
        local delta_x, delta_y = x - resize.start_x, y - resize.start_y
        local minimum_width = panel.minimum_width
        local minimum_height = panel.minimum_height + HEADER_HEIGHT

        if resize.edges.left then
            local right = resize.rect.x + resize.rect.width
            rect.x = math.min(resize.rect.x + delta_x, right - minimum_width)
            rect.width = right - rect.x
        elseif resize.edges.right then
            rect.width = math.max(minimum_width, resize.rect.width + delta_x)
        end
        if resize.edges.top then
            local bottom = resize.rect.y + resize.rect.height
            rect.y = math.min(resize.rect.y + delta_y, bottom - minimum_height)
            rect.height = bottom - rect.y
        elseif resize.edges.bottom then
            rect.height = math.max(minimum_height, resize.rect.height + delta_y)
        end
        self:layout()
        return true
    end
    if self.splitter_drag then
        local drag = self.splitter_drag
        local delta = (drag.region == "left" and x - drag.start_x)
            or (drag.region == "right" and drag.start_x - x)
            or (drag.region == "top" and y - drag.start_y)
            or (drag.start_y - y)
        self.sizes[drag.region] = math.max(80, drag.start_size + delta)
        self:layout()
        return true
    end
    if self.pending_drag and not self.dragging_panel then
        local drag = self.pending_drag
        if math.abs(x - drag.start_x) + math.abs(y - drag.start_y) >= 5 then
            local panel = drag.panel
            local panel_rect
            if panel.floating then
                panel_rect = copyRect(panel.floating)
            else
                local stack = panel.stack
                panel_rect = { x = stack.x, y = stack.y, width = math.max(panel.preferred_width, stack.width),
                    height = math.max(panel.preferred_height, stack.height) }
            end
            self:floatPanel(panel, panel_rect)
            self.dragging_panel = panel
            self.drag_offset_x = drag.offset_x
            self.drag_offset_y = drag.offset_y
        end
    end
    if self.dragging_panel then
        local rect = self.dragging_panel.floating
        rect.x, rect.y = x - self.drag_offset_x, y - self.drag_offset_y
        if self:isDockingSuppressed() then
            self.dock_preview = nil
        else
            self.dock_preview = self:getDockTarget(x, y, self.dragging_panel)
        end
        self:layout()
        return true
    end
    if self.captured_control then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        self.captured_control:onMouseMoved(local_x, local_y, dx, dy)
        return true
    end
    return false
end

function EditorDockSpace:isDockingSuppressed()
    return Input.keyDown("shift") == true
end

function EditorDockSpace:onMouseReleased(x, y, button, presses)
    if button == 1 and self.floating_resize then
        self.floating_resize = nil
        return true
    end
    if button == 1 and self.splitter_drag then
        self.splitter_drag = nil
        return true
    end
    if button == 1 and self.dragging_panel then
        if self.dock_preview and not self:isDockingSuppressed() then
            if self.dock_preview.split_target then
                self:dockPanelSplit(self.dragging_panel, self.dock_preview.split_target, self.dock_preview.side)
            else
                self:dockPanel(self.dragging_panel, self.dock_preview.stack)
            end
        end
        self.dragging_panel = nil
        self.pending_drag = nil
        self.dock_preview = nil
        return true
    end
    self.pending_drag = nil
    if self.captured_control then
        local target = self.captured_control
        local local_x, local_y = target:toLocal(x, y)
        target:onMouseReleased(local_x, local_y, button, presses)
        self.captured_control = nil
        return true
    end
    return false
end

function EditorDockSpace:getDockTarget(x, y, moving_panel)
    local targets = {
        left = { x = self.x, y = self.y, width = math.min(self.sizes.left, self.width / 2), height = self.height },
        right = { x = self.x + self.width - math.min(self.sizes.right, self.width / 2), y = self.y,
            width = math.min(self.sizes.right, self.width / 2), height = self.height },
        top = { x = self.x, y = self.y, width = self.width, height = math.min(self.sizes.top, self.height / 2) },
        bottom = { x = self.x, y = self.y + self.height - math.min(self.sizes.bottom, self.height / 2),
            width = self.width, height = math.min(self.sizes.bottom, self.height / 2) }
    }
    if x < self.x + EDGE_TARGET_SIZE then return { stack = self.stacks.left, rect = targets.left } end
    if x > self.x + self.width - EDGE_TARGET_SIZE then return { stack = self.stacks.right, rect = targets.right } end
    if y < self.y + EDGE_TARGET_SIZE then return { stack = self.stacks.top, rect = targets.top } end
    if y > self.y + self.height - EDGE_TARGET_SIZE then return { stack = self.stacks.bottom, rect = targets.bottom } end
    for _, stack in ipairs(self:getStacks()) do
        local rect = { x = stack.x, y = stack.y, width = stack.width, height = stack.height }
        if not stack:isEmpty() and not (stack:getActivePanel() == moving_panel and #stack.panels == 1)
            and pointInRect(x, y, rect) then
            local horizontal = stack.region == "top" or stack.region == "bottom"
            local extent = horizontal and rect.width or rect.height
            local position = horizontal and x or y
            local start = horizontal and rect.x or rect.y
            local split_size = math.min(extent * 0.28, 90)
            if extent >= 160 and position < start + split_size then
                return {
                    split_target = stack,
                    side = horizontal and "left" or "top",
                    rect = horizontal
                        and { x = rect.x, y = rect.y, width = rect.width / 2, height = rect.height }
                        or { x = rect.x, y = rect.y, width = rect.width, height = rect.height / 2 }
                }
            elseif extent >= 160 and position > start + extent - split_size then
                return {
                    split_target = stack,
                    side = horizontal and "right" or "bottom",
                    rect = horizontal
                        and { x = rect.x + rect.width / 2, y = rect.y,
                            width = rect.width / 2, height = rect.height }
                        or { x = rect.x, y = rect.y + rect.height / 2,
                            width = rect.width, height = rect.height / 2 }
                }
            end
            return { stack = stack, rect = rect }
        end
    end
    local center = self.stacks.center
    local center_rect = { x = center.x, y = center.y, width = center.width, height = center.height }
    if pointInRect(x, y, center_rect) then return { stack = center, rect = center_rect } end
end

function EditorDockSpace:getMapPanelDropTarget(x, y)
    for _, stack in ipairs(self:getStacks()) do
        local header = self:getStackHeaderRect(stack)
        if pointInRect(x, y, header) then
            return {
                stack = stack,
                rect = { x = stack.x, y = stack.y, width = stack.width, height = stack.height }
            }
        end
    end
    local target = self:getDockTarget(x, y)
    if target and target.stack and target.stack:isEmpty() then return target end
end

function EditorDockSpace:onWheelMoved(x, y)
    local mouse_x, mouse_y = love.mouse.getPosition()
    local target = self:getControlAt(mouse_x, mouse_y)
    if target then
        local handled = target:onWheelMoved(x, y)
        if handled and target.focus_on_wheel then self:setFocus(target) end
        return handled
    end
end

function EditorDockSpace:onKeyPressed(key, is_repeat)
    if self.dragging_panel and (key == "lshift" or key == "rshift") then
        self.dock_preview = nil
        return true
    end
    if self.focused_control then return self.focused_control:onKeyPressed(key, is_repeat) end
end

function EditorDockSpace:onKeyReleased(key)
    if self.dragging_panel and (key == "lshift" or key == "rshift") then
        local x, y = love.mouse.getPosition()
        self.dock_preview = self:getDockTarget(x, y, self.dragging_panel)
        return true
    end
    if self.focused_control then return self.focused_control:onKeyReleased(key) end
end

function EditorDockSpace:onTextInput(text)
    if self.focused_control then return self.focused_control:onTextInput(text) end
end

function EditorDockSpace:captureLayout()
    local layout = { sizes = TableUtils.copy(self.sizes), regions = {}, floating = {}, panels = {} }
    for _, region in ipairs(REGIONS) do
        local region_layout = { stacks = {} }
        layout.regions[region] = region_layout
        for _, stack in ipairs(self.region_stacks[region]) do
            if not stack:isEmpty() then
                local stack_layout = {
                    id = stack.id,
                    active = stack:getActivePanel() and stack:getActivePanel().id,
                    panels = {}
                }
                for _, panel in ipairs(stack.panels) do table.insert(stack_layout.panels, panel.id) end
                table.insert(region_layout.stacks, stack_layout)
            end
        end
    end
    for _, panel in ipairs(self.floating) do
        table.insert(layout.floating, { id = panel.id, rect = copyRect(panel.floating) })
    end
    for _, panel in ipairs(self.panel_order) do
        layout.panels[panel.id] = {
            visible = panel.visible,
            last_region = panel.stack and panel.stack.id or panel.last_region
        }
    end
    return layout
end

function EditorDockSpace:restoreLayout(layout)
    if not layout then return end
    local previous_visibility = {}
    for _, panel in ipairs(self.panel_order) do previous_visibility[panel] = panel.visible end
    for _, stack in ipairs(self:getStacks()) do
        for _, panel in ipairs(stack.panels) do panel.stack = nil end
        stack.panels = {}
        stack.active_index = 1
    end
    for _, region in ipairs(REGIONS) do
        local base = self.stacks[region]
        self.region_stacks[region] = { base }
    end
    for id, stack in pairs(self.stacks) do
        if id ~= stack.region then self.stacks[id] = nil end
    end
    for _, panel in ipairs(self.floating) do panel.floating = nil end
    self.floating = {}
    for _, panel in ipairs(self.panel_order) do
        local configuration = layout.panels and layout.panels[panel.id]
        if configuration then
            panel.visible = configuration.visible ~= false
            panel.last_region = configuration.last_region or panel.last_region
        end
    end
    for region, size in pairs(layout.sizes or {}) do
        if self.sizes[region] then self.sizes[region] = size end
    end
    local placed = {}
    for _, region in ipairs(REGIONS) do
        local region_layout = layout.regions and layout.regions[region]
        if region_layout then
            local saved_stacks = region_layout.stacks
            if type(saved_stacks) ~= "table" then
                saved_stacks = { { active = region_layout.active, panels = region_layout.panels or {} } }
            end
            for stack_index, stack_layout in ipairs(saved_stacks) do
                local stack = stack_index == 1 and self.stacks[region]
                    or self:createStack(region, stack_layout.id)
                for _, id in ipairs(stack_layout.panels or {}) do
                    local panel = self.panels[id]
                    if panel and panel.visible then
                        stack:addPanel(panel)
                        panel.last_region = stack.id
                        placed[panel] = true
                    end
                end
                local active = stack_layout.active and self.panels[stack_layout.active]
                if active and active.visible then stack:setActivePanel(active) end
                if stack:isEmpty() and stack ~= self.stacks[region] then
                    self.stacks[stack.id] = nil
                end
            end
        end
    end
    for _, entry in ipairs(layout.floating or {}) do
        local panel = self.panels[entry.id]
        if panel and panel.visible then
            self:floatPanel(panel, copyRect(entry.rect))
            placed[panel] = true
        end
    end
    for _, panel in ipairs(self.panel_order) do
        if panel.visible and not placed[panel] then
            local stack = self.stacks[panel.last_region] or self.stacks.center
            stack:addPanel(panel)
            panel.last_region = stack.id
        end
    end
    self:removeEmptySplitStacks()
    self:layout()
    for _, panel in ipairs(self.panel_order) do
        if panel.on_visibility_changed and previous_visibility[panel] ~= panel.visible then
            panel.on_visibility_changed(panel, panel.visible)
        end
    end
end

return EditorDockSpace
