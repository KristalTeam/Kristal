---@class EditorObjectReferencePicker : EditorControl
---@overload fun(editor: Editor, value?: any, options?: table): EditorObjectReferencePicker
local EditorObjectReferencePicker, super = Class(EditorControl)

local function isMarkerLayer(layer)
    local type_id = layer._editor_type_id or layer.type
    if type_id == "markers" or tostring(layer.name or ""):lower() == "markers" then return true end
    if Registry.layer_types then
        local layer_type = Registry.layer_types:getLegacyTiledType(layer)
        return layer_type and layer_type.id == "markers"
    end
    return false
end

local function getObjectType(object)
    return object.type or object.class
        or object.properties and object.properties.type
        or ""
end

local function getObjectLabel(object, object_id, marker)
    local name = tostring(object.name or "")
    local object_type = tostring(getObjectType(object) or "")
    local primary = name ~= "" and name
        or object_type ~= "" and object_type
        or (marker and "Marker " or "Object ") .. tostring(object_id)
    if name ~= "" and object_type ~= "" and name ~= object_type then
        return primary .. " [" .. object_type .. "]"
    end
    return primary
end

function EditorObjectReferencePicker:init(editor, value, options)
    local width, height = editor:getUIDimensions()
    super.init(self, 0, 0, width, height)
    self.editor = editor
    self.options = options or {}
    self.value = EditorObjectReference.from(value, self.options.map_id)
    self.focused_control = nil
    self.captured_control = nil
    self.search = self:addChild(EditorSearchBar({
        editor = editor,
        placeholder = "Search maps, objects, and markers...",
        on_changed = function(filter) self.tree:setFilter(filter) end,
        on_submit = function() return self:apply() end
    }))
    self.tree = self:addChild(EditorTreeList({
        on_select = function(node) self:selectNode(node) end,
        on_activate = function(node)
            if node and node.reference then
                self.value = node.reference
                self:apply()
            end
        end,
        on_request_focus = function(control) self:setFocus(control) end,
        icon_scale = 1
    }))
    self.apply_button = self:addChild(EditorButton("Apply", function() self:apply() end))
    self.cancel_button = self:addChild(EditorButton("Cancel", function() self:cancel() end))
    self:populate()
    self:setFocus(self.search)
end

function EditorObjectReferencePicker:getMapLayers(map_id, data)
    for _, document in ipairs(self.editor.map_documents or {}) do
        if document.map_lookup and document.map_lookup[map_id] then
            return document:getEditableLayers(map_id), document
        end
    end
    return data.layers or {}, nil
end

function EditorObjectReferencePicker:populate()
    self.tree:clear()
    local map_ids = {}
    for map_id in pairs(Registry.map_data or {}) do table.insert(map_ids, map_id) end
    table.sort(map_ids, function(a, b) return tostring(a):lower() < tostring(b):lower() end)

    local selected_node
    for _, map_id in ipairs(map_ids) do
        local data = Registry.getMapData(map_id)
        local layers, document = self:getMapLayers(map_id, data)
        local map_name = tostring(data.name or "")
        local map_label = map_name ~= "" and map_name ~= map_id
            and (map_name .. " (" .. tostring(map_id) .. ")") or tostring(map_id)
        local map_node = self.tree:newNode("folder", map_label, {
            expanded = self.value.map_id == map_id,
            renameable = false,
            draggable = false
        })
        map_node.parent = self.tree.root
        table.insert(self.tree.root.children, map_node)

        MapUtils.walkLayers(layers, function(layer)
            local marker_layer = isMarkerLayer(layer)
            if self.options.marker and not marker_layer then return end
            if not layer.objects or #layer.objects == 0 then return end
            local layer_node = self.tree:newNode("folder", tostring(layer.name or "Objects"), {
                expanded = self.value.map_id == map_id,
                renameable = false,
                draggable = false,
                badge_text = marker_layer and "markers" or nil,
                badge_color = marker_layer and { 0.95, 0.76, 0.25, 1 } or nil
            })
            layer_node.parent = map_node
            table.insert(map_node.children, layer_node)
            for _, object in ipairs(layer.objects) do
                local object_id = document and document:getObjectId(object) or object.id or object._editor_uid
                if object_id ~= nil then
                    local reference = EditorObjectReference(map_id, object_id)
                    local node = self.tree:newNode("object", getObjectLabel(object, object_id, marker_layer), {
                        renameable = false,
                        draggable = false,
                        badge_text = marker_layer and "marker" or tostring(getObjectType(object) or ""),
                        badge_color = marker_layer and { 0.95, 0.76, 0.25, 1 } or nil
                    })
                    node.reference = reference
                    node.object_name = object.name
                    node.parent = layer_node
                    table.insert(layer_node.children, node)
                    if reference:matches(self.value.map_id, self.value.object_id) then selected_node = node end
                end
            end
            if #layer_node.children == 0 then TableUtils.removeValue(map_node.children, layer_node) end
        end)
        if #map_node.children == 0 then
            TableUtils.removeValue(self.tree.root.children, map_node)
        end
    end
    self.tree:refreshVisibleNodes()
    if selected_node then
        local parent = selected_node.parent
        while parent and parent ~= self.tree.root do
            parent.expanded = true
            parent = parent.parent
        end
        self.tree:refreshVisibleNodes()
        self.tree:selectNode(selected_node)
    end
end

function EditorObjectReferencePicker:selectNode(node)
    if node and node.reference then self.value = node.reference end
end

function EditorObjectReferencePicker:setFocus(control)
    if self.focused_control == control then return end
    if self.focused_control then self.focused_control:onBlur() end
    self.focused_control = control
    if control then control:onFocus() end
end

function EditorObjectReferencePicker:apply()
    local selected = self.tree.selected_node
    local selected_visible = selected and self.tree:getVisibleIndex(selected)
    if selected_visible and selected.reference then
        self.value = selected.reference
    elseif self.search.value ~= "" then
        for _, entry in ipairs(self.tree.visible_nodes) do
            if entry.node.reference then
                self.value = entry.node.reference
                break
            end
        end
    end
    if not self.value or self.value.object_id == nil then return false end
    if self.options.on_apply and self.options.on_apply(self.value) == false then return false end
    return self.editor:closeObjectReferencePicker(true)
end

function EditorObjectReferencePicker:cancel()
    return self.editor:closeObjectReferencePicker(false)
end

function EditorObjectReferencePicker:update(dt)
    self:setBounds(0, 0, self.editor:getUIDimensions())
    self.panel_width, self.panel_height = math.min(680, self.width - 40), math.min(600, self.height - 40)
    self.panel_x = math.floor((self.width - self.panel_width) / 2)
    self.panel_y = math.floor((self.height - self.panel_height) / 2)
    self.search:setBounds(self.panel_x + 18, self.panel_y + 52, self.panel_width - 36, 28)
    self.tree:setBounds(self.panel_x + 18, self.panel_y + 88,
        self.panel_width - 36, math.max(40, self.panel_height - 142))
    self.apply_button:setBounds(self.panel_x + self.panel_width - 222,
        self.panel_y + self.panel_height - 42, 98, 28)
    self.cancel_button:setBounds(self.panel_x + self.panel_width - 116,
        self.panel_y + self.panel_height - 42, 98, 28)
    super.update(self, dt)
end

function EditorObjectReferencePicker:onMousePressed(x, y, button, _, presses)
    if button ~= 1 then return true end
    local target = self:getControlAt(x, y)
    if target and target ~= self then
        if target.focusable then self:setFocus(target) else self:setFocus(nil) end
        local local_x, local_y = target:toLocal(x, y)
        if target:onMousePressed(local_x, local_y, button, presses) then self.captured_control = target end
        return true
    end
    self:setFocus(nil)
    if x < self.panel_x or y < self.panel_y
        or x >= self.panel_x + self.panel_width or y >= self.panel_y + self.panel_height then
        return self:cancel()
    end
    return true
end

function EditorObjectReferencePicker:onMouseMoved(x, y, dx, dy)
    if self.captured_control then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        self.captured_control:onMouseMoved(local_x, local_y, dx, dy)
    end
    return true
end

function EditorObjectReferencePicker:onMouseReleased(x, y, button, _, presses)
    if self.captured_control then
        local target = self.captured_control
        local local_x, local_y = target:toLocal(x, y)
        target:onMouseReleased(local_x, local_y, button, presses)
        self.captured_control = nil
    end
    return true
end

function EditorObjectReferencePicker:onKeyPressed(key, is_repeat)
    if key == "escape" then return self:cancel() end
    if key == "tab" then
        local controls = { self.search, self.tree, self.apply_button, self.cancel_button }
        local index = 0
        for candidate, control in ipairs(controls) do
            if control == self.focused_control then index = candidate break end
        end
        index = ((index - 1 + (Input.shift() and -1 or 1)) % #controls) + 1
        self:setFocus(controls[index])
        return true
    end
    if self.focused_control == self.search
        and (key == "up" or key == "down" or key == "left" or key == "right"
            or key == "home" or key == "end") then
        return self.tree:onKeyPressed(key)
    end
    if self.focused_control and self.focused_control:onKeyPressed(key, is_repeat) then return true end
    if (key == "return" or key == "kpenter") and not is_repeat then return self:apply() end
    return true
end

function EditorObjectReferencePicker:onKeyReleased(key)
    if self.focused_control then self.focused_control:onKeyReleased(key) end
    return true
end

function EditorObjectReferencePicker:onTextInput(text)
    if self.focused_control then self.focused_control:onTextInput(text) end
    return true
end

function EditorObjectReferencePicker:onWheelMoved(x, y)
    local mouse_x, mouse_y = self.editor:getMousePosition()
    if self.tree:containsPoint(mouse_x, mouse_y) then self.tree:onWheelMoved(x, y) end
    return true
end

function EditorObjectReferencePicker:getCursorType(x, y)
    local target = self:getControlAt(x, y)
    if not target or target == self then return "default" end
    local local_x, local_y = target:toLocal(x, y)
    return target.getCursorType and target:getCursorType(local_x, local_y)
        or target.cursor_type or "default"
end

function EditorObjectReferencePicker:drawSelf()
    Draw.setColor(0, 0, 0, 0.68)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.105, 0.105, 0.125, 1)
    love.graphics.rectangle("fill", self.panel_x, self.panel_y,
        self.panel_width, self.panel_height, 4)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", self.panel_x + 0.5, self.panel_y + 0.5,
        self.panel_width - 1, self.panel_height - 1, 4)
    love.graphics.setFont(EditorFont.get(24))
    Draw.setColor(0.94, 0.94, 0.97, 1)
    love.graphics.print(self.options.title or "Choose Object Reference",
        self.panel_x + 18, self.panel_y + 14)
end

return EditorObjectReferencePicker
