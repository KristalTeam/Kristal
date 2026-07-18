--- Handles map tools and pointer interaction in map views.
---@class EditorMapInteraction : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorMapInteraction
local EditorMapInteraction = Class()

function EditorMapInteraction:init(editor)
    self.editor = editor
end

function EditorMapInteraction:setActiveTool(id)
    local self = self.editor
    if not self.tool_registry:get(id) then return false end
    if id ~= "shape" then self:cancelPolygonBuilds() end
    if id ~= "object" then self:cancelEventRegionDrags() end
    if id ~= "link" then self:cancelObjectLink(true) end
    self.active_tool = id
    if id == "terrain_brush" and self.terrain_palette_panel then
        if not self.terrain_palette_panel.visible then
            self.dockspace:setPanelVisible(self.terrain_palette_panel, true)
        end
        if self.terrain_palette_panel.stack then
            self.terrain_palette_panel.stack:setActivePanel(self.terrain_palette_panel)
        end
        if self.message_bar then
            self.message_bar:setStatus("Terrain Brush: left-drag to paint, right-drag to erase")
        end
    end
    self.placement_event_id = id == "object" and self.selected_event_id or nil
    return true
end

function EditorMapInteraction:cancelPolygonBuilds()
    local self = self.editor
    local cancelled = false
    for _, document in ipairs(self.map_documents or {}) do
        if document.map_view and document.map_view.polygon_build then
            document.map_view:cancelPolygon()
            cancelled = true
        end
    end
    return cancelled
end

function EditorMapInteraction:cancelEventRegionDrags()
    local self = self.editor
    local cancelled = false
    for _, document in ipairs(self.map_documents or {}) do
        if document.map_view and document.map_view.event_region_drag then
            document.map_view:cancelEventRegion()
            cancelled = true
        end
        if document.map_view and document.map_view.event_paint_stroke then
            document.map_view:cancelEventPaint()
            cancelled = true
        end
    end
    return cancelled
end

function EditorMapInteraction:setPlacementEvent(id)
    local self = self.editor
    if not Registry.getEditorEvent(id) then return false end
    self:cancelPolygonBuilds()
    self:cancelEventRegionDrags()
    self.selected_event_id = id
    self.placement_event_id = id
    self.active_tool = "object"
    return true
end

function EditorMapInteraction:beginAssetDrag(kind, id, label)
    local self = self.editor
    self.asset_drag = { kind = kind, id = id, label = label or id }
    local icon
    if kind == "drawfx" then icon = "editor/ui/tool/brush" end
    self:beginDragPreview(kind, label or id, icon, id)
    return true
end

function EditorMapInteraction:beginProjectFileDrag(data, icon)
    local self = self.editor
    if type(data) ~= "table" or data.type ~= "file" then return false end
    self.project_file_drag = { data = data }
    self:beginDragPreview("project_file", data.relative_path or data.name, icon, data)
    return true
end

function EditorMapInteraction:updateProjectFileDrag(x, y)
    local self = self.editor
    if not self.project_file_drag then return false end
    self.project_file_drag.x, self.project_file_drag.y = x, y
    self:updateDragPreview(x, y)
    return true
end

function EditorMapInteraction:cancelProjectFileDrag()
    local self = self.editor
    if not self.project_file_drag then return false end
    self.project_file_drag = nil
    self:finishDragPreview()
    return true
end

function EditorMapInteraction:finishProjectFileDrag(x, y)
    local self = self.editor
    local drag = self.project_file_drag
    self.project_file_drag = nil
    self:finishDragPreview()
    if not drag then return false end
    local target = self.dockspace:getControlAt(x, y)
    while target do
        if target.acceptProjectFileDrop and target:acceptProjectFileDrop(drag.data) then return true end
        target = target.parent
    end
    return false
end

function EditorMapInteraction:beginDragPreview(kind, label, icon, data)
    local self = self.editor
    self.drag_preview = { kind = kind, label = label, icon = icon, data = data }
    if kind == "event" then
        local event_class = Registry.getEditorEvent(data)
        local point = event_class and event_class.placement_shape == "point"
        local shape = point and "point" or "rectangle"
        local success, event = pcall(Registry.createEditorEvent, data, {
            x = point and 0 or -20, y = point and 0 or -20, shape = shape,
            width = point and 0 or 40, height = point and 0 or 40,
            properties = {}
        }, {})
        if success then self.drag_preview.event = event end
    end
    return true
end

function EditorMapInteraction:updateDragPreview(x, y)
    local self = self.editor
    if not self.drag_preview then return false end
    self.drag_preview.x, self.drag_preview.y = x, y
    return true
end

function EditorMapInteraction:finishDragPreview()
    local self = self.editor
    self.drag_preview = nil
end

function EditorMapInteraction:updateAssetDrag(x, y)
    local self = self.editor
    if not self.asset_drag then return false end
    self.asset_drag.x, self.asset_drag.y = x, y
    self:updateDragPreview(x, y)
    return true
end

function EditorMapInteraction:getMapViewAt(x, y)
    local self = self.editor
    for _, document in ipairs(self.map_documents or {}) do
        local panel = document.panel
        if panel and panel.content == document.map_view and self.dockspace:isPanelDisplayed(panel)
            and document.map_view:containsPoint(x, y) then
            return document.map_view
        end
    end
end

function EditorMapInteraction:getMapObjectAtScreen(x, y)
    local self = self.editor
    local view = self:getMapViewAt(x, y)
    if not view then return nil end
    local local_x, local_y = view:toLocal(x, y)
    local world_x, world_y = view:getMapCoordinates(local_x, local_y)
    return view.document:findObjectAt(world_x, world_y, { all_layers = true }), view, world_x, world_y
end

function EditorMapInteraction:finishAssetDrag(x, y)
    local self = self.editor
    local drag = self.asset_drag
    self.asset_drag = nil
    self:finishDragPreview()
    if not drag then return false end
    local selection, view, world_x, world_y = self:getMapObjectAtScreen(x, y)
    if drag.kind == "drawfx" then
        if not selection then
            self:addWarning("Drop DrawFX onto an event or shape", nil, "drawfx_drop")
            return false
        end
        self:selectMapObject(selection)
        return self:applyDrawFXToSelection(drag.id)
    elseif drag.kind == "event" and view then
        local event_class = Registry.getEditorEvent(drag.id)
        if event_class and event_class.placement_shape == "region" then
            return self:setPlacementEvent(drag.id)
        end
        return self:placeEvent(view, drag.id, world_x, world_y)
    end
    return false
end

function EditorMapInteraction:placeEvent(view, event_id, world_x, world_y)
    local self = self.editor
    self:beginHistoryTransaction("Place Event", view.document)
    local object, layer_or_reason, map_id = view.document:addEditorObject(event_id, nil, world_x, world_y)
    if not object then
        self:cancelHistoryTransaction()
        self:addWarning(layer_or_reason, nil, "event_placement")
        return false
    end
    self:clearDiagnostics("event_placement")
    local selection = view.document:getObjectSelection(map_id, layer_or_reason, object)
    selection.view = view
    self:selectMapObject(selection)
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:setActiveTool("select")
    return true
end

function EditorMapInteraction:getMapObjectPropertiesTarget(selection)
    local self = self.editor
    local data = selection.data
    data.properties = data.properties or {}
    data.__editor_property_types = data.__editor_property_types or {}
    local event_id = selection.document:getEditorObjectType(data, selection.map_id)
    local layer_type = Registry.getLayerType(selection.layer._editor_type_id)
    local editor_event = Registry.createEditorEvent(event_id, data, {
        depth = tonumber(selection.layer._editor_depth_offset) or 0,
        layer_uid = selection.layer._editor_uid,
        layer = selection.layer,
        layer_type = layer_type,
        layer_color = Registry.layer_types:getLayerColor(selection.layer, layer_type),
        map_id = selection.map_id,
        map_data = Registry.getMapData(selection.map_id)
    })
    data.__editor_fx = data.__editor_fx or {}
    local fx_sections = {}
    for index, assignment in ipairs(data.__editor_fx) do
        if type(assignment) == "string" then
            assignment = { id = assignment, properties = {}, __editor_property_types = {} }
            data.__editor_fx[index] = assignment
        end
        local definition = Registry.getEditorDrawFX(assignment.id)
        if definition then
            local current_assignment = assignment
            local fx = Registry.createEditorDrawFX(assignment.id, assignment)
            table.insert(fx_sections, {
                title = fx:getName(),
                property_set = fx.property_set,
                on_changed = function() selection.document:invalidatePreview(selection.map_id) end,
                on_remove = function()
                    self:performHistoryEdit("Remove DrawFX", selection.document, function()
                        return TableUtils.removeValue(data.__editor_fx, current_assignment) ~= nil
                    end)
                    self:setPropertiesTarget(self:getMapObjectPropertiesTarget(selection), self)
                end
            })
        end
    end
    local function numberField(label, key)
        return EditorPropertyFields.number(data, label, key, {
            on_set = function() selection.document:invalidatePreview(selection.map_id) end
        })
    end
    local function valueField(label, key)
        return EditorPropertyFields.value(data, label, key, {
            on_set = function() selection.document:invalidatePreview(selection.map_id) end
        })
    end
    local tile_object = data.gid or data.tileset and data.tile_id ~= nil
    local name_field = valueField("Name", "name")
    name_field.compact = true
    local type_field = valueField("Type", "type")
    type_field.compact = true
    type_field.rebuild_target = function()
        return self:getMapObjectPropertiesTarget(selection)
    end
    local fields = {
        name_field, type_field,
        numberField("X", "x"), numberField("Y", "y")
    }
    if tile_object then
        local tileset_choices = {}
        for id in pairs(Registry.tilesets or {}) do table.insert(tileset_choices, id) end
        table.sort(tileset_choices)
        table.insert(fields, {
            label = "Tileset", compact = true,
            get = function() return data.tileset or "" end,
            set = function(value) data.tileset = value ~= "" and value or nil return true end,
            choices = tileset_choices
        })
        table.insert(fields, numberField("Tile ID", "tile_id"))
        table.insert(fields, {
            label = "Flip X", compact = true,
            get = function() return data.flip_x == true end,
            set = function(value) data.flip_x = value == true return true end,
            choices = { { value = false, label = "No" }, { value = true, label = "Yes" } }
        })
        table.insert(fields, {
            label = "Flip Y", compact = true,
            get = function() return data.flip_y == true end,
            set = function(value) data.flip_y = value == true return true end,
            choices = { { value = false, label = "No" }, { value = true, label = "Yes" } }
        })
    else
        table.insert(fields, {
            label = "Shape",
            get = function() return selection.document:getObjectShape(selection) end,
            set = function(shape) return selection.document:setObjectShape(selection, shape) end,
            choices = {
                { value = "point", label = "Point" },
                { value = "rectangle", label = "Rectangle" },
                { value = "ellipse", label = "Ellipse" },
                { value = "line", label = "Line" },
                { value = "polygon", label = "Polygon" },
                { value = "polyline", label = "Polyline" }
            },
            rebuild = true
        })
    end
    table.insert(fields, numberField("Width", "width"))
    table.insert(fields, numberField("Height", "height"))
    if not tile_object and editor_event.scaling_mode == "scale" then
        table.insert(fields, numberField("Scale X", "scale_x"))
        table.insert(fields, numberField("Scale Y", "scale_y"))
    end
    table.insert(fields, numberField("Rotation", "rotation"))
    table.insert(fields, {
        label = "DrawFX",
        get = function()
            local ids = {}
            for _, assignment in ipairs(data.__editor_fx or {}) do
                table.insert(ids, type(assignment) == "table" and assignment.id or assignment)
            end
            return table.concat(ids, ", ")
        end,
        set = function() return false end,
        readonly = true
    })
    return {
        title = tile_object and "Tile Object"
            or event_id and (StringUtils.titleCase(tostring(event_id):gsub("[/_]", " "))) or "Map Object",
        history_owner = selection.document,
        fields = fields,
        properties = data.properties,
        property_types = data.__editor_property_types,
        property_set = editor_event.property_set,
        fx_sections = fx_sections,
        on_changed = function() selection.document:invalidatePreview(selection.map_id) end
    }
end

function EditorMapInteraction:isMapObjectSelected(selection)
    local self = self.editor
    if not selection then return false end
    for _, candidate in ipairs(self.selected_map_objects or {}) do
        if candidate.document == selection.document and candidate.data == selection.data then return true end
    end
    return false
end

function EditorMapInteraction:getSelectedMapObjects(document)
    local self = self.editor
    local result = {}
    for _, selection in ipairs(self.selected_map_objects or {}) do
        if not document or selection.document == document then table.insert(result, selection) end
    end
    return result
end

function EditorMapInteraction:getMapObjectBatchPropertiesTarget(selections)
    local self = self.editor
    local function sharedValue(key)
        local value = selections[1] and (selections[1].data[key] or 0) or 0
        for index = 2, #selections do
            if (selections[index].data[key] or 0) ~= value then return "" end
        end
        return value
    end
    local function batchNumberField(label, key)
        return {
            label = label,
            compact = true,
            placeholder = "Mixed",
            get = function() return sharedValue(key) end,
            set = function(value)
                local number = tonumber(value)
                if not number then return false end
                local invalidated = {}
                for _, selection in ipairs(selections) do
                    selection.data[key] = number
                    invalidated[selection.map_id] = selection.document
                end
                for map_id, document in pairs(invalidated) do document:invalidatePreview(map_id) end
                return true
            end
        }
    end
    return {
        title = tostring(#selections) .. " Objects",
        history_owner = selections[1] and selections[1].document,
        fields = { batchNumberField("Rotation", "rotation") }
    }
end

function EditorMapInteraction:selectMapObjects(selections, primary)
    local self = self.editor
    local unique, result = {}, {}
    for _, selection in ipairs(selections or {}) do
        local key = selection.document and tostring(selection.document) .. ":" .. tostring(selection.data)
        if selection.data and not unique[key] then
            unique[key] = true
            table.insert(result, selection)
        end
    end
    if primary then
        for index, selection in ipairs(result) do
            if selection.document == primary.document and selection.data == primary.data then
                table.remove(result, index)
                table.insert(result, 1, selection)
                break
            end
        end
    end
    self.selected_map_objects = result
    self.selected_map_object = result[1]
    if self.selected_map_object then
        local selection = self.selected_map_object
        selection.document:setSelectedLayer(selection.layer._editor_uid, selection.map_id)
        if self.layers_browser and self.active_document == selection.document then
            self.layers_browser:focusLayer(selection.document, selection.map_id, selection.layer)
        end
    end
    if #result == 1 then
        self:setPropertiesTarget(self:getMapObjectPropertiesTarget(result[1]), self)
    elseif #result > 1 then
        self:setPropertiesTarget(self:getMapObjectBatchPropertiesTarget(result), self)
    else
        self:clearPropertiesTarget(self)
    end
    return #result > 0
end

function EditorMapInteraction:selectMapObject(selection, additive)
    local self = self.editor
    if not additive then return self:selectMapObjects(selection and { selection } or {}, selection) end
    local selections = self:getSelectedMapObjects()
    local found
    for index, candidate in ipairs(selections) do
        if candidate.document == selection.document and candidate.data == selection.data then
            table.remove(selections, index)
            found = true
            break
        end
    end
    if not found then table.insert(selections, selection) end
    return self:selectMapObjects(selections, found and nil or selection)
end

function EditorMapInteraction:deleteSelectedMapObject(explode, history_label)
    local self = self.editor
    local selections = self:getSelectedMapObjects()
    if #selections == 0 then return false end
    local owners = {}
    for _, selection in ipairs(selections) do table.insert(owners, selection.document) end
    self:beginHistoryTransaction(history_label or (explode and "Explode Objects" or "Delete Objects"), owners)
    local removed = false
    local explosions = {}
    for _, selection in ipairs(selections) do
        if explode and selection.view then
            local x, y = selection.document:getObjectWorldCenter(selection)
            selection.view:addExplosion(x, y)
            table.insert(explosions, { document = selection.document, x = x, y = y })
        end
        removed = selection.document:removeEditorObject(selection) or removed
    end
    if removed then
        if #explosions > 0 then self:setHistoryMetadata("explosions", explosions) end
        self:markHistoryChanged()
        self:commitHistoryTransaction()
        self:selectMapObjects({})
    else
        self:cancelHistoryTransaction()
    end
    return removed
end

function EditorMapInteraction:copySelectedMapObjects(silent)
    local self = self.editor
    local selected = self:getSelectedMapObjects()
    if #selected == 0 then return false end
    local objects = {}
    for _, selection in ipairs(selected) do
        table.insert(objects, {
            data = TableUtils.copy(selection.data, true),
            document = selection.document,
            map_id = selection.map_id
        })
    end
    self.map_object_clipboard = { objects = objects, paste_count = 0, cut = false }
    if not silent and self.message_bar then
        self.message_bar:setStatus(string.format("Copied %d object%s", #objects, #objects == 1 and "" or "s"))
    end
    return true
end

function EditorMapInteraction:cutSelectedMapObjects()
    local self = self.editor
    local count = #(self.selected_map_objects or {})
    if not self:copySelectedMapObjects(true) then return false end
    if not self:deleteSelectedMapObject(false, "Cut Objects") then return false end
    self.map_object_clipboard.cut = true
    if self.message_bar then
        self.message_bar:setStatus(string.format("Cut %d object%s", count, count == 1 and "" or "s"))
    end
    return true
end

function EditorMapInteraction:pasteMapObjects()
    local self = self.editor
    local clipboard = self.map_object_clipboard
    local document = self.active_document
    if not clipboard or not clipboard.objects or #clipboard.objects == 0 or not document then return false end
    local view = document.map_view
    local map_id = view and view.active_map_id or document.primary_map_id
    if not document.map_lookup[map_id] then map_id = document.primary_map_id end
    local layer = document:getSelectedObjectLayer(map_id)
    if not layer then
        if self.message_bar then self.message_bar:setStatus("Select an object layer before pasting") end
        return false
    end
    local first_cut_paste = clipboard.cut == true
    if first_cut_paste then
        clipboard.cut = false
        clipboard.paste_count = 0
    else
        clipboard.paste_count = (clipboard.paste_count or 0) + 1
    end
    local grid_width, grid_height = document:getTileLayerCellSize(nil, map_id)
    local offset_x = grid_width * (clipboard.paste_count or 0)
    local offset_y = grid_height * (clipboard.paste_count or 0)
    self:beginHistoryTransaction("Paste Objects", document)
    local pasted = {}
    layer.objects = layer.objects or {}
    for _, stored in ipairs(clipboard.objects) do
        local object = TableUtils.copy(stored.data, true)
        local preserve_id = first_cut_paste and stored.document == document and stored.map_id == map_id
        if not preserve_id then object.id = nil end
        object._editor_uid = nil
        object.x = (object.x or 0) + offset_x
        object.y = (object.y or 0) + offset_y
        document:getObjectId(object)
        table.insert(layer.objects, object)
        local selection = document:getObjectSelection(map_id, layer, object)
        selection.view = view
        table.insert(pasted, selection)
    end
    if #pasted == 0 then
        self:cancelHistoryTransaction()
        return false
    end
    document:invalidatePreview(map_id)
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:selectMapObjects(pasted, pasted[1])
    if self.message_bar then
        self.message_bar:setStatus(string.format("Pasted %d object%s", #pasted, #pasted == 1 and "" or "s"))
    end
    return true
end

function EditorMapInteraction:duplicateSelectedMapObject()
    local self = self.editor
    local selected = self:getSelectedMapObjects()
    local owners = {}
    for _, selection in ipairs(selected) do table.insert(owners, selection.document) end
    self:beginHistoryTransaction("Duplicate Objects", owners)
    local duplicates = {}
    for _, selection in ipairs(selected) do
        local object, layer = selection.document:duplicateEditorObject(selection)
        if object then
            local duplicate = selection.document:getObjectSelection(selection.map_id, layer, object)
            duplicate.view = selection.view
            table.insert(duplicates, duplicate)
        end
    end
    if #duplicates == 0 then self:cancelHistoryTransaction() return false end
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:selectMapObjects(duplicates, duplicates[1])
    return true
end

function EditorMapInteraction:applyDrawFXToSelection(fx_id)
    local self = self.editor
    local selection = self.selected_map_object
    if not selection then return false end
    self:beginHistoryTransaction("Add DrawFX", selection.document)
    if not selection.document:addObjectFX(selection, fx_id) then
        self:cancelHistoryTransaction()
        return false
    end
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:setPropertiesTarget(self:getMapObjectPropertiesTarget(selection), self)
    return true
end

function EditorMapInteraction:getDrawFXMenuItems()
    local self = self.editor
    local items = {}
    for _, definition in ipairs(Registry.getEditorDrawFXAll()) do
        local fx_id = definition.id
        table.insert(items, {
            label = definition.name,
            action = function() self:applyDrawFXToSelection(fx_id) end
        })
    end
    return items
end

function EditorMapInteraction:openMapObjectContext(selection, x, y)
    local self = self.editor
    if not self:isMapObjectSelected(selection) then self:selectMapObject(selection) end
    return self.dockspace:openContextMenu({
        { label = "Properties", action = function()
            self.dockspace:setPanelVisible(self.properties_panel, true, self.properties_panel.last_region or "right")
            if self.properties_panel.stack then self.properties_panel.stack:setActivePanel(self.properties_panel) end
        end },
        { label = "Duplicate", action = function() self:duplicateSelectedMapObject() end },
        { label = "Add DrawFX", children = self:getDrawFXMenuItems() },
        { label = "Delete", action = function() self:deleteSelectedMapObject(false) end },
        { label = "Explode", action = function() self:deleteSelectedMapObject(true) end }
    }, x, y, selection.view)
end

function EditorMapInteraction:startObjectReferenceDrag(control)
    local self = self.editor
    if not self.selected_map_object then
        self:addWarning("Select the source object before linking an object-reference property",
            nil, "object_reference")
        return false
    end
    self.object_reference_drag = { control = control, source = self.selected_map_object }
    if self.message_bar then
        self.message_bar:setStatus("Linking object reference: drop onto a target object (Esc to cancel)", 3600)
    end
    return true
end

function EditorMapInteraction:isObjectReferenceTargetAllowed(selection, definition)
    if not selection or not selection.data then return false end
    return MapUtils.isObjectTypeAllowed(
        selection.document:getEditorObjectType(selection.data, selection.map_id),
        definition and definition.allowed_types)
end

function EditorMapInteraction:getObjectReferenceLabel(value)
    local self = self.editor
    local source = self.selected_map_object
    local reference = EditorObjectReference.from(value, source and source.map_id)
    local object_name
    for _, document in ipairs(self.map_documents or {}) do
        local selection = document:resolveObjectReference(reference)
        if selection then
            object_name = selection.data.name
            if object_name ~= nil and object_name ~= "" then break end
        end
    end
    if (object_name == nil or object_name == "") and reference.map_id then
        local data = Registry.getMapData(reference.map_id)
        if data then
            MapUtils.walkObjects(data.layers, function(object)
                if object_name == nil and tostring(object.id) == tostring(reference.object_id)
                    and object.name ~= nil and object.name ~= "" then
                    object_name = object.name
                end
            end)
        end
    end
    return reference:getLabel(object_name)
end

function EditorMapInteraction:finishObjectReferenceDrag(x, y)
    local self = self.editor
    local drag = self.object_reference_drag
    self.object_reference_drag = nil
    if not drag then return nil end
    local selection = self:getMapObjectAtScreen(x, y)
    if not selection then
        self:addWarning("Drop the reference link onto an event or shape", nil, "object_reference")
        return nil
    end
    if not self:isObjectReferenceTargetAllowed(selection, drag.control.options) then
        self:addWarning("This field only accepts object types: "
            .. table.concat(drag.control.options.allowed_types, ", "), nil, "object_reference")
        return nil
    end
    self:clearDiagnostics("object_reference")
    if self.message_bar then self.message_bar:setStatus("Linked object reference") end
    return drag.source.document:createObjectReference(selection)
end

function EditorMapInteraction:getObjectLinkProperties(selection)
    local self = self.editor
    if not selection or not selection.data then return {} end
    local data = selection.data
    data.properties = data.properties or {}
    data.__editor_property_types = data.__editor_property_types or {}
    local event_id = selection.document:getEditorObjectType(data, selection.map_id)
    local success, event = pcall(Registry.createEditorEvent, event_id, data, {
        map_id = selection.map_id
    })
    if not success or not event then return {} end
    local result = {}
    for _, definition in ipairs(event.property_set:getProperties()) do
        if (definition.type == "object_reference" or definition.type == "marker_reference")
            and not definition.unavailable then
            table.insert(result, {
                id = definition.id,
                name = definition.name or StringUtils.titleCase(definition.id:gsub("_", " ")),
                definition = definition,
                property_set = event.property_set
            })
        end
    end
    return result
end

function EditorMapInteraction:startObjectLink(selection, property)
    local self = self.editor
    self.object_link = {
        source = selection,
        property_id = property.id,
        property_name = property.name,
        property_set = property.property_set,
        definition = property.definition
    }
    self:selectMapObject(selection)
    self:clearDiagnostics("object_link")
    if self.message_bar then
        self.message_bar:setStatus("Linking " .. property.name .. ": click a target object (Esc to cancel)", 3600)
    end
    return true
end

function EditorMapInteraction:chooseObjectLink(selection, x, y)
    local self = self.editor
    local properties = self:getObjectLinkProperties(selection)
    if #properties == 0 then
        self:addWarning("This object has no object-reference properties to link", nil, "object_link")
        return false
    end
    if #properties == 1 then return self:startObjectLink(selection, properties[1]) end
    local items = {}
    for _, property in ipairs(properties) do
        local choice = property
        table.insert(items, {
            label = choice.name,
            action = function() self:startObjectLink(selection, choice) end
        })
    end
    self:selectMapObject(selection)
    if self.message_bar then self.message_bar:setStatus("Choose which reference property to link") end
    return self.dockspace:openContextMenu(items, x, y, selection.view)
end

function EditorMapInteraction:finishObjectLink(target)
    local self = self.editor
    local link = self.object_link
    if not link then return false end
    if not target then
        if self.message_bar then
            self.message_bar:setStatus("Linking " .. link.property_name .. ": click a target object (Esc to cancel)", 3600)
        end
        return true
    end
    if target.document == link.source.document and target.data == link.source.data then
        if self.message_bar then self.message_bar:setStatus("The source cannot link to itself", 2.5) end
        return true
    end
    if not self:isObjectReferenceTargetAllowed(target, link.definition) then
        if self.message_bar then
            self.message_bar:setStatus("This field only accepts object types: "
                .. table.concat(link.definition.allowed_types, ", "), 3)
        end
        return true
    end
    local reference = link.source.document:createObjectReference(target)
    local changed = self:performHistoryEdit("Link " .. link.property_name, link.source.document, function()
        if not link.property_set:setValue(link.property_id, reference) then return false end
        link.source.document:invalidatePreview(link.source.map_id)
        return true
    end)
    if not changed then return false end
    self.object_link = nil
    self:selectMapObject(link.source)
    self:clearDiagnostics("object_link")
    if self.message_bar then self.message_bar:setStatus("Linked " .. link.property_name) end
    return true
end

function EditorMapInteraction:cancelObjectLink(silent)
    local self = self.editor
    if not self.object_link then return false end
    self.object_link = nil
    if not silent and self.message_bar then self.message_bar:setStatus("Object link cancelled") end
    return true
end

return EditorMapInteraction
