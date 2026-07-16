---@class EditorLayersPanel : EditorControl
---@overload fun(editor: table): EditorLayersPanel
local EditorLayersPanel, super = Class(EditorControl)

function EditorLayersPanel:init(editor)
    super.init(self, 0, 0, 300, 500)
    self.editor = editor
    self.document = nil
    self.map_id = nil
    self.selected_layer = nil
    self.updating_fields = false
    self.detail_y = 0

    self.darken_toggle = self:addChild(EditorCheckbox("Darken Unselected",
        editor.darken_unselected_layers ~= false, function(value)
            if editor.settings and editor.settings:getSetting("appearance.darken_unselected") then
                editor.settings:setValue("appearance.darken_unselected", value)
            else
                editor.darken_unselected_layers = value
            end
        end))
    self.new_button = self:addChild(EditorButton("New Layer", function() self:openNewLayerMenu() end))
    self.list = self:addChild(EditorTreeList({
        row_height = 28,
        on_select = function(node) self:selectLayer(node and node.data) end,
        on_toggle = function(node, expanded)
            if node.data then node.data._editor_expanded = expanded end
        end,
        on_rename = function(node, _, new_name) self:renameLayer(node.data, new_name) end,
        on_move = function(node) self:applyLayerTreeMove(node) end,
        on_drag_start = function(node)
            local layer_type = self:getLayerType(node.data)
            self.editor:beginDragPreview("layer", node.name, layer_type and layer_type.icon, node.data)
        end,
        on_drag_move = function(_, list, x, y)
            local gx, gy = list:getGlobalPosition()
            self.editor:updateDragPreview(gx + x, gy + y)
        end,
        on_drag_end = function()
            self.editor:finishDragPreview()
        end,
        on_context_menu = function(node, list, x, y) self:openLayerContextMenu(node, list, x, y) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))
end

function EditorLayersPanel:setDocument(document, map_id)
    map_id = map_id or document and document.primary_map_id
    if self.document == document and self.map_id == map_id then return end
    self.document = document
    self.map_id = map_id
    self.new_button.enabled = document ~= nil
    self.selected_layer = nil
    self:refreshList(document and document:getSelectedLayer(map_id))
end

function EditorLayersPanel:focusLayer(document, map_id, layer)
    if self.document ~= document or self.map_id ~= map_id then
        self.document = document
        self.map_id = map_id
        self.selected_layer = layer
        self:refreshList(layer and layer._editor_uid)
        return
    end
    local node = layer and self:findLayerNode(layer._editor_uid)
    if node then self.list:selectNode(node) end
    self:selectLayer(layer)
end

function EditorLayersPanel:getNewLayerItems(parent_uid)
    local items = {}
    for _, layer_type in ipairs(Registry.getLayerTypes()) do
        if layer_type.id ~= "default" then
            local type_id = layer_type.id
            table.insert(items, {
                label = layer_type.name,
                action = function() self:createLayer(type_id, parent_uid) end
            })
        end
    end
    return items
end

function EditorLayersPanel:openNewLayerMenu()
    if not self.document then return false end
    local x, y = self.new_button:getGlobalPosition()
    return self.editor.dockspace:openContextMenu(self:getNewLayerItems(), x, y + self.new_button.height,
        self.new_button)
end

function EditorLayersPanel:openLayerContextMenu(node, list, x, y)
    local items = {
        { label = "New Layer", children = self:getNewLayerItems() }
    }
    if node then
        local layer = node.data
        if layer._editor_kind_id == "group" then
            table.insert(items, {
                label = layer._editor_expanded == false and "Expand" or "Collapse",
                action = function() self:toggleGroup(layer) end
            })
            table.insert(items, {
                label = "New Child Layer",
                children = self:getNewLayerItems(layer._editor_uid)
            })
        end
        table.insert(items, { label = "Rename", action = function() list:beginRename(node) end })
        table.insert(items, {
            label = "Delete Layer",
            action = function()
                self:selectLayer(layer)
                self:deleteLayer()
            end
        })
    end
    local global_x, global_y = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, global_x + x, global_y + y, list)
end

function EditorLayersPanel:getLayers()
    return self.document and self.document:getFlatEditableLayers(self.map_id, true) or {}
end

function EditorLayersPanel:getLayerType(layer)
    return layer and (Registry.getLayerType(layer._editor_type_id) or Registry.getLayerType("default"))
end

function EditorLayersPanel:getLayerColor(layer)
    return Registry.layer_types:getLayerColor(layer, self:getLayerType(layer))
end

function EditorLayersPanel:findLayerNode(uid)
    local found
    local function visit(parent)
        for _, node in ipairs(parent.children or {}) do
            if node.data and node.data._editor_uid == uid then found = node return end
            visit(node)
            if found then return end
        end
    end
    visit(self.list.root)
    return found
end

function EditorLayersPanel:refreshList(selected_uid)
    selected_uid = selected_uid or (self.selected_layer and self.selected_layer._editor_uid)
    self.list.root.children = {}
    local function append(layers, parent)
        for index = #(layers or {}), 1, -1 do
            local layer = layers[index]
            local layer_type = self:getLayerType(layer)
            local node = self.list:newNode(layer._editor_kind_id == "group" and "layer_group" or "layer",
                layer.name or "Unnamed Layer", {
                    container = layer._editor_kind_id == "group",
                    expanded = layer._editor_expanded ~= false,
                    data = layer,
                    icon = layer_type and layer_type.icon,
                    color = self:getLayerColor(layer),
                    right_icon = layer._editor_visible == false and "editor/ui/eye_closed" or "editor/ui/eye_open",
                    right_action = function() self:toggleLayerVisibility(layer) end
                })
            node.parent = parent
            table.insert(parent.children, node)
            if node.children then append(layer.layers, node) end
        end
    end
    append(self.document and self.document:getEditableLayers(self.map_id) or {}, self.list.root)
    self.list:refreshVisibleNodes()
    local selected_node = selected_uid and self:findLayerNode(selected_uid)
        or self.list.visible_nodes[1] and self.list.visible_nodes[1].node
    if selected_node then
        self.list:selectNode(selected_node)
        self:selectLayer(selected_node.data)
    else
        self.list:selectNode(nil)
        self:selectLayer(nil)
    end
end

function EditorLayersPanel:toggleGroup(layer)
    if not layer or layer._editor_kind_id ~= "group" then return false end
    local node = self:findLayerNode(layer._editor_uid)
    return node and self.list:toggleFolder(node) or false
end

function EditorLayersPanel:selectLayer(layer)
    self.selected_layer = layer
    if self.document then
        self.document:setSelectedLayer(layer and layer._editor_uid or nil, self.map_id)
    end
    if layer then
        self.editor:setPropertiesTarget(self:getPropertiesTarget(layer), self)
    else
        self.editor:clearPropertiesTarget(self)
    end
end

function EditorLayersPanel:getPropertiesTarget(layer)
    local layer_type = self:getLayerType(layer)
    local fields = {
        {
            id = "color",
            label = "Color",
            control = "color",
            compact = true,
            placeholder = "#RRGGBBAA",
            get = function() return ColorUtils.RGBAToHex(self:getLayerColor(layer)) end,
            set = function(value) return self:setLayerColor(layer, value) end
        },
        {
            id = "depth",
            label = "Depth Override",
            compact = true,
            placeholder = "Automatic",
            get = function() return layer._editor_depth_override or "" end,
            set = function(value, submitted) return self:setLayerDepth(layer, value, submitted) end
        },
        EditorPropertyFields.number(layer, "Parallax X", "parallaxx", { default = 1 }),
        EditorPropertyFields.number(layer, "Parallax Y", "parallaxy", { default = 1 })
    }
    if layer._editor_kind_id == "image" or (layer_type and layer_type.kind == "image") then
        table.insert(fields, 1, {
            id = "image",
            label = "Image Source",
            control = "path",
            path_kind = "asset",
            asset_registry = { "texture", "frames" },
            path_root = "assets/sprites",
            strip_extension = true,
            placeholder = "Sprite asset ID or path",
            get = function() return layer.image or "" end,
            set = function(value) return self:setLayerImage(layer, value) end
        })
    end
    return {
        title = (layer.name or "Unnamed Layer") .. " (" .. (layer_type and layer_type.name or "Unknown") .. ")",
        history_owner = self.document,
        properties = layer.properties,
        property_types = layer._editor_property_types,
        property_set = layer._editor_property_set,
        fields = fields,
        on_changed = function() self:changed(false) end
    }
end

function EditorLayersPanel:toggleLayerVisibility(layer)
    if not self.document or not layer then return false end
    self.editor:beginHistoryTransaction("Toggle Layer Visibility", self.document)
    self.document:setEditableLayerVisible(layer._editor_uid, layer._editor_visible == false, self.map_id)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList(self.selected_layer and self.selected_layer._editor_uid)
    return true
end

function EditorLayersPanel:changed(refresh_list)
    if not self.document or not self.selected_layer then return end
    self.document:invalidatePreview(self.map_id)
    if refresh_list then self:refreshList(self.selected_layer._editor_uid) end
end

function EditorLayersPanel:renameLayer(layer, value)
    if not layer or value == "" then return false end
    self.editor:beginHistoryTransaction("Rename Layer", self.document)
    layer.name = value
    local used = {}
    for _, entry in ipairs(self.document:getFlatEditableLayers(self.map_id)) do
        if entry.layer ~= layer and entry.layer.id then used[entry.layer.id] = true end
    end
    layer.id = EditorFormat.uniqueSlug(value, used, "layer")
    if self.selected_layer == layer then
        self.editor:setPropertiesTarget(self:getPropertiesTarget(layer), self)
    end
    self:changed(false)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    return true
end

function EditorLayersPanel:setLayerColor(layer, value)
    if not layer then return false end
    local color = ColorUtils.tryHexToRGB(value)
    if color then
        layer.color = color
        self.editor:clearDiagnostics("layer_color")
        local node = self:findLayerNode(layer._editor_uid)
        if node then node.color = self:getLayerColor(layer) end
        return true
    else
        self.editor:addWarning("Layer color must use #RRGGBB or #RRGGBBAA", nil, "layer_color")
        return false
    end
end

function EditorLayersPanel:setLayerImage(layer, value)
    if not layer then return false end
    value = StringUtils.trim(tostring(value or ""))
    if value == "" then
        layer.image = nil
        layer.image_width = nil
        layer.image_height = nil
        self.editor:clearDiagnostics("layer_image")
        return true
    end
    local texture, asset_id = Assets.resolveTextureReference(value)
    if not texture then
        self.editor:addWarning("Could not resolve image layer source '" .. value .. "'", nil, "layer_image")
        return false
    end
    layer.image = asset_id
    layer.image_width, layer.image_height = texture:getDimensions()
    self.editor:clearDiagnostics("layer_image")
    return true
end

function EditorLayersPanel:setLayerDepth(layer, value, submitted)
    if not layer then return false end
    local depth = value == "" and false or tonumber(value)
    if depth ~= nil then
        layer._editor_depth_override = depth or nil
        self.editor:clearDiagnostics("layer_depth")
        return true
    elseif submitted then
        self.editor:addWarning("Layer depth override must be a number or blank", nil, "layer_depth")
    end
    return false
end

function EditorLayersPanel:createLayer(type_id, parent_uid)
    if not self.document then return false end
    self.editor:beginHistoryTransaction("Create Layer", self.document)
    local layer = self.document:createEditableLayer(type_id, self.map_id, parent_uid)
    if not layer then self.editor:cancelHistoryTransaction() return false end
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList(layer._editor_uid)
    return true
end

function EditorLayersPanel:deleteLayer()
    if not self.document or not self.selected_layer then return false end
    local layers = self:getLayers()
    local index = 1
    for candidate_index, entry in ipairs(layers) do
        if entry.layer == self.selected_layer then index = candidate_index break end
    end
    self.editor:beginHistoryTransaction("Delete Layer", self.document)
    self.document:removeEditableLayer(self.selected_layer._editor_uid, self.map_id)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self.selected_layer = nil
    local next_entry = #layers > 0 and layers[MathUtils.clamp(index, 1, #layers)] or nil
    self:refreshList(next_entry and next_entry.layer._editor_uid)
    return true
end

function EditorLayersPanel:applyLayerTreeMove(node)
    if not self.document or not node or not node.data then return false end
    local function build(parent)
        local layers = {}
        for index = #(parent.children or {}), 1, -1 do
            local child = parent.children[index]
            local layer = child.data
            if child.children then layer.layers = build(child) end
            table.insert(layers, layer)
        end
        return layers
    end
    self.editor:beginHistoryTransaction("Reorder Layer", self.document)
    self.document.editable_layers[self.map_id] = build(self.list.root)
    self.document:invalidatePreview(self.map_id)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList(node.data._editor_uid)
    return true
end

function EditorLayersPanel:update(dt)
    local padding = 8
    self.darken_toggle:setBounds(padding, 6, math.max(0, self.width - padding * 2), 28)
    self.new_button:setBounds(padding, 38, math.max(0, self.width - padding * 2), 28)
    local list_height = math.max(0, self.height - 82)
    self.list:setBounds(padding, 74, math.max(0, self.width - padding * 2), list_height)
    super.update(self, dt)
end

function EditorLayersPanel:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return EditorLayersPanel
