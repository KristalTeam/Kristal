---@class EditorMapDocument : EditorDocument
---@overload fun(editor: table, map_id?: string): EditorMapDocument
local EditorMapDocument, super = Class(EditorDocument)

local function flattenLayers(layers, result, parent)
    result = result or {}
    parent = parent or {
        offsetx = 0,
        offsety = 0,
        parallaxx = 1,
        parallaxy = 1,
        properties = {}
    }
    for _, source in ipairs(layers or {}) do
        local layer = TableUtils.copy(source, true)
        layer.properties = TableUtils.mergeMany(parent.properties, layer.properties or {})
        layer.offsetx = (layer.offsetx or 0) + parent.offsetx
        layer.offsety = (layer.offsety or 0) + parent.offsety
        layer.parallaxx = (layer.parallaxx or 1) * parent.parallaxx
        layer.parallaxy = (layer.parallaxy or 1) * parent.parallaxy
        if layer.type == "group" then
            flattenLayers(layer.layers, result, layer)
        else
            table.insert(result, layer)
        end
    end
    return result
end

local function setupLayerProperties(layer)
    layer.properties = layer.properties or {}
    local properties
    if type(layer.properties[1]) == "table" and layer.properties[1].name then
        properties = EditorPropertySet.fromEntries(layer.properties, { owner = layer })
        layer.properties = properties and properties.values or {}
        layer._editor_property_types = properties and properties.types or {}
    else
        layer._editor_property_types = layer._editor_property_types or {}
        properties = EditorPropertySet(layer.properties, layer._editor_property_types)
    end
    Registry.layer_types:initializeLayerProperties(layer, properties)
    layer._editor_property_set = properties
end

local function stripLayerRuntimeState(layers)
    MapUtils.walkLayers(layers, function(layer) layer._editor_property_set = nil end)
end

function EditorMapDocument:init(editor, map_id)
    super.init(self, editor)
    self.world = EditorWorld(map_id and ("session:" .. map_id) or nil)
    self.primary_map_id = self.world.primary_map_id
    self.maps = self.world.maps
    self.map_lookup = self.world.map_lookup
    self.editable_layers = {}
    self.selected_layers = {}
    self.next_layer_uid = 1
    self.next_object_uid = 1
    if map_id then self:setPrimaryMap(map_id) end
end

function EditorMapDocument:captureHistoryState()
    local layers = TableUtils.copy(self.editable_layers, true)
    for _, map_layers in pairs(layers) do
        stripLayerRuntimeState(map_layers)
    end
    local maps = {}
    for _, entry in ipairs(self.maps) do
        table.insert(maps, {
            id = entry.id, x = entry.x, y = entry.y,
            explicit_companion = entry.explicit_companion == true,
            primary = entry.id == self.primary_map_id
        })
    end
    return {
        world_id = self.world.id,
        world_name = self.world.name,
        world_data = TableUtils.copy(self.world.data or {}, true),
        world_properties = TableUtils.copy(self.world.properties or {}, true),
        world_property_types = TableUtils.copy(self.world.__editor_property_types or {}, true),
        world_virtual = self.world.virtual,
        primary_map_id = self.primary_map_id,
        maps = maps,
        editable_layers = layers,
        selected_layers = TableUtils.copy(self.selected_layers, true),
        next_layer_uid = self.next_layer_uid,
        next_object_uid = self.next_object_uid
    }
end

function EditorMapDocument:restoreHistoryState(state)
    if not state then return false end
    local selected_layers = self.selected_layers
    self.previous_world_id = self.world and self.world.id
    local world = EditorWorld(state.world_id)
    world.name = state.world_name or state.world_id
    world.data = TableUtils.copy(state.world_data or {}, true)
    world.properties = TableUtils.copy(state.world_properties or {}, true)
    world.__editor_property_types = TableUtils.copy(state.world_property_types or {}, true)
    world.virtual = state.world_virtual
    for _, saved in ipairs(state.maps or {}) do
        local entry = world:addMap(saved.id, saved.x, saved.y, {
            explicit_companion = saved.explicit_companion
        })
        if entry then
            entry.explicit_companion = saved.explicit_companion
            entry.primary = saved.primary == true
        end
    end
    world.primary_map_id = state.primary_map_id
    self.world = world
    self.primary_map_id = state.primary_map_id
    self.maps, self.map_lookup = world.maps, world.map_lookup
    self.editable_layers = TableUtils.copy(state.editable_layers or {}, true)
    for _, layers in pairs(self.editable_layers) do
        MapUtils.walkLayers(layers, setupLayerProperties)
    end
    self.selected_layers = selected_layers or {}
    self.next_layer_uid = state.next_layer_uid or 1
    self.next_object_uid = state.next_object_uid or 1
    for _, entry in ipairs(self.maps) do
        entry.preview, entry.preview_attempted = nil, false
    end
    return true
end

function EditorMapDocument:getFormatContext(map_id)
    return EditorFormatDocument.getMapContext(self, map_id)
end

function EditorMapDocument:buildEditorFormatData(map_id, options)
    return EditorFormatDocument.buildMapData(self, map_id, options)
end

function EditorMapDocument:save(path, options, map_id)
    return EditorFormatDocument.saveMap(self, path, options, map_id)
end

function EditorMapDocument:adoptSavedMapData(id, data)
    self.editable_layers[id] = nil
    self.selected_layers[id] = nil
    self:getEditableLayers(id)
    self:invalidatePreview(id)
end

function EditorMapDocument:getEditableLayers(id)
    id = id or self.primary_map_id
    if not id then return {} end
    if not self.editable_layers[id] then
        local data = Registry.getMapData(id)
        local reader_class = Registry.getMapReader(id)
        local legacy = reader_class and reader_class.LEGACY_FORMAT
        local layers = legacy and flattenLayers(data and data.layers or {})
            or TableUtils.copy(data and data.layers or {}, true)
        MapUtils.walkLayers(layers, function(layer)
            layer._editor_uid = self.next_layer_uid
            self.next_layer_uid = self.next_layer_uid + 1
            layer.properties = layer.properties or {}
            local layer_type = legacy
                and Registry.layer_types:getLegacyTiledType(layer)
                or Registry.getLayerType(layer._editor_type_id or layer.type or "default")
            layer._editor_type_id = layer_type and layer_type.id or "default"
            layer._editor_kind_id = layer.kind or (layer_type and layer_type.kind) or "object"
            layer._editor_visible = layer.visible ~= false
            if layer._editor_kind_id == "group" then
                layer.layers = layer.layers or {}
                if layer._editor_expanded == nil then layer._editor_expanded = true end
            end
            setupLayerProperties(layer)
        end)
        MapUtils.walkObjects(layers, function(object)
            local object_id = tonumber(object.id)
            if object_id and object_id >= 1 and object_id % 1 == 0 then
                self.next_object_uid = math.max(self.next_object_uid, object_id + 1)
            end
        end)
        self.editable_layers[id] = layers
    end
    return self.editable_layers[id]
end


function EditorMapDocument:getFlatEditableLayers(id, visible_only)
    local result = {}
    local function append(layers, depth, parent, ancestors_visible)
        for _, layer in ipairs(layers or {}) do
            local visible = ancestors_visible and layer._editor_visible ~= false
            table.insert(result, { layer = layer, depth = depth, parent = parent, visible = visible })
            local expanded = not visible_only or layer._editor_expanded ~= false
            if expanded and layer.layers then
                append(layer.layers, depth + 1, layer, visible)
            end
        end
    end
    append(self:getEditableLayers(id), 0, nil, true)
    return result
end

function EditorMapDocument:getAllEditableLayers(id)
    local result = {}
    for _, entry in ipairs(self:getFlatEditableLayers(id, false)) do table.insert(result, entry.layer) end
    return result
end

function EditorMapDocument:findEditableLayer(uid, id)
    local found, found_parent, found_list, found_index
    MapUtils.walkLayers(self:getEditableLayers(id), function(layer, _, parent, list, index)
        if not found and layer._editor_uid == uid then
            found, found_parent, found_list, found_index = layer, parent, list, index
        end
    end)
    return found, found_parent, found_list, found_index
end

function EditorMapDocument:setSelectedLayer(uid, id)
    id = id or self.primary_map_id
    if not id then return false end
    self.selected_layers[id] = uid
    return true
end

function EditorMapDocument:getSelectedLayer(id)
    return self.selected_layers[id or self.primary_map_id]
end

function EditorMapDocument:isLayerSelectable(layer, id)
    if not layer or not self.editor or self.editor.darken_unselected_layers == false then return true end
    id = id or self.primary_map_id
    local selected_uid = self:getSelectedLayer(id)
    if selected_uid == nil then return true end
    local selectable = false
    local function visit(layers, selected_ancestor)
        for _, candidate in ipairs(layers or {}) do
            local selected = selected_ancestor or candidate._editor_uid == selected_uid
            if candidate == layer then selectable = selected return end
            if candidate.layers then visit(candidate.layers, selected) end
            if selectable then return end
        end
    end
    visit(self:getEditableLayers(id), false)
    return selectable
end

function EditorMapDocument:setEditableLayerVisible(uid, visible, id)
    id = id or self.primary_map_id
    local layer = self:findEditableLayer(uid, id)
    if not layer then return false end
    layer._editor_visible = visible ~= false
    layer.visible = layer._editor_visible
    return true
end

function EditorMapDocument:invalidatePreview(id)
    local entry = self.map_lookup[id or self.primary_map_id]
    if not entry then return false end
    entry.preview = nil
    entry.preview_attempted = false
    return true
end

function EditorMapDocument:createEditableLayer(type_id, id, parent_uid)
    id = id or self.primary_map_id
    local data = Registry.getMapData(id)
    if not data then return nil end
    local root_layers = self:getEditableLayers(id)
    local layers = root_layers
    if parent_uid then
        local parent = self:findEditableLayer(parent_uid, id)
        if parent and parent._editor_kind_id == "group" then
            parent.layers = parent.layers or {}
            layers = parent.layers
        end
    end
    local used, index = {}, 1
    for _, entry in ipairs(self:getFlatEditableLayers(id)) do used[(entry.layer.name or ""):lower()] = true end
    local layer_type = Registry.getLayerType(type_id or "tile") or Registry.getLayerType("default")
    local name = "New " .. (layer_type and layer_type.name or "Layer")
    while used[name:lower()] do
        index = index + 1
        name = "New " .. (layer_type and layer_type.name or "Layer") .. " " .. index
    end
    local kind = layer_type and layer_type.kind or "object"
    local used_ids = {}
    for _, entry in ipairs(self:getFlatEditableLayers(id)) do
        if entry.layer.id then used_ids[entry.layer.id] = true end
    end
    local layer = {
        _editor_uid = self.next_layer_uid,
        _editor_type_id = layer_type and layer_type.id or "default",
        _editor_kind_id = kind,
        type = kind == "group" and "group"
            or (kind == "tile" and "tilelayer" or (kind == "image" and "imagelayer" or "objectgroup")),
        name = name,
        id = EditorFormat.uniqueSlug(name, used_ids, "layer"),
        width = data.width or 16,
        height = data.height or 12,
        visible = true,
        _editor_visible = true,
        opacity = 1,
        offsetx = 0,
        offsety = 0,
        parallaxx = 1,
        parallaxy = 1,
        properties = {},
        _editor_property_types = {},
        color = TableUtils.copy(layer_type and layer_type.color or { 0.8, 0.8, 0.82, 1 }, true)
    }
    self.next_layer_uid = self.next_layer_uid + 1
    if kind == "tile" then
        local reader_class = Registry.getMapReader(id)
        if reader_class and reader_class.LEGACY_FORMAT then
            layer.encoding = "lua"
            layer.data = {}
            for tile = 1, layer.width * layer.height do layer.data[tile] = 0 end
        else
            layer.kind = "tile"
            layer.tileset = self.editor and self.editor.active_tileset_id or nil
            layer.chunks = {}
        end
    elseif kind == "object" then
        layer.objects = {}
    elseif kind == "group" then
        layer.layers = {}
        layer._editor_expanded = true
    end
    table.insert(layers, layer)
    setupLayerProperties(layer)
    self:invalidatePreview(id)
    return layer
end

function EditorMapDocument:removeEditableLayer(uid, id)
    id = id or self.primary_map_id
    local layer, _, layers, index = self:findEditableLayer(uid, id)
    if not layer then return nil end
    table.remove(layers, index)
    self:invalidatePreview(id)
    return layer
end

function EditorMapDocument:moveEditableLayer(uid, target_index, id, parent_uid)
    id = id or self.primary_map_id
    local layer, _, source_layers, source_index = self:findEditableLayer(uid, id)
    if not layer then return false end
    local target_layers = self:getEditableLayers(id)
    if parent_uid then
        local parent = self:findEditableLayer(parent_uid, id)
        if not parent or parent._editor_kind_id ~= "group" then return false end
        -- A group cannot become its own descendant.
        local descendant = false
        MapUtils.walkLayers(layer.layers or {}, function(candidate)
            if candidate == parent then descendant = true end
        end)
        if descendant or parent == layer then return false end
        parent.layers = parent.layers or {}
        target_layers = parent.layers
    end
    if source_layers == target_layers and source_index < target_index then target_index = target_index - 1 end
    if source_layers == target_layers and source_index == target_index then return false end
    table.remove(source_layers, source_index)
    table.insert(target_layers, MathUtils.clamp(target_index, 1, #target_layers + 1), layer)
    self:invalidatePreview(id)
    return true
end

function EditorMapDocument:hasMap(id)
    return self.world:hasMap(id)
end

function EditorMapDocument:addMap(id, x, y, options)
    options = options or {}
    local entry = self.world:addMap(id, x, y, options)
    if options.primary then self:setPrimaryMap(id) end
    return entry
end

function EditorMapDocument:setPrimaryMap(id)
    if not self.world:setPrimaryMap(id) then return false end
    self.primary_map_id = id
    return true
end

function EditorMapDocument:getPrimaryMap()
    return self.world:getPrimaryMap()
end

function EditorMapDocument:setMapPosition(id, x, y)
    return self.world:setMapPosition(id, x, y)
end

function EditorMapDocument:removeMap(id)
    return self.world:removeMap(id)
end

function EditorMapDocument:getObjectId(object)
    object.properties = object.properties or {}
    local id = tonumber(object.id)
    if not id or id < 1 or id % 1 ~= 0 then
        id = self.next_object_uid
        self.next_object_uid = self.next_object_uid + 1
        object.id = id
    else
        self.next_object_uid = math.max(self.next_object_uid, id + 1)
    end
    object._editor_uid = id
    return id
end

function EditorMapDocument:getSelectedObjectLayer(id)
    id = id or self.primary_map_id
    local selected = self:getSelectedLayer(id)
    local fallback
    for _, layer in ipairs(self:getAllEditableLayers(id)) do
        local layer_type = Registry.getLayerType(layer._editor_type_id)
        if layer._editor_uid == selected and layer_type and layer_type.kind == "object" then return layer end
        if layer_type and layer_type.kind == "object" and (not fallback or layer._editor_type_id == "objects") then
            fallback = layer
        end
    end
    return selected == nil and fallback or nil
end

function EditorMapDocument:getSelectedTileLayer(id)
    id = id or self.primary_map_id
    local selected = self:getSelectedLayer(id)
    local fallback
    for _, layer in ipairs(self:getAllEditableLayers(id)) do
        local layer_type = Registry.getLayerType(layer._editor_type_id)
        if layer_type and layer_type.kind == "tile" then
            if layer._editor_uid == selected then return layer end
            fallback = fallback or layer
        end
    end
    return selected == nil and fallback or nil
end

function EditorMapDocument:getTileLayerGridSize(layer, id)
    local data = Registry.getMapData(id or self.primary_map_id) or {}
    return math.max(0, tonumber(layer and layer.width) or tonumber(data.width) or 0),
        math.max(0, tonumber(layer and layer.height) or tonumber(data.height) or 0)
end

function EditorMapDocument:getTileLayerCellSize(layer, id)
    local entry = self.map_lookup[id or self.primary_map_id]
    local data = Registry.getMapData(id or self.primary_map_id) or {}
    return tonumber(layer and layer.tile_width_override) or tonumber(data.grid_width)
            or tonumber(data.tilewidth) or entry and entry.tile_width or 40,
        tonumber(layer and layer.tile_height_override) or tonumber(data.grid_height)
            or tonumber(data.tileheight) or entry and entry.tile_height or 40
end

function EditorMapDocument:getLegacyTilesetFirstGid(map_id, tileset_id)
    local data = Registry.getMapData(map_id) or {}
    local short_id = tostring(tileset_id or ""):match("([^/]+)$")
    for _, reference in ipairs(data.tilesets or {}) do
        local name = reference.name
        if name == tileset_id or name == short_id then return reference.firstgid or 1 end
    end
end

function EditorMapDocument:getEncodedTile(layer, column, row, map_id)
    local width, height = self:getTileLayerGridSize(layer, map_id)
    if column < 0 or row < 0 or column >= width or row >= height then return nil end
    if layer.chunks then
        local size = EditorFormat.CHUNK_SIZE
        local chunk_x, chunk_y = math.floor(column / size) * size, math.floor(row / size) * size
        for _, chunk in ipairs(layer.chunks) do
            if chunk.x == chunk_x and chunk.y == chunk_y then
                return chunk.tile_data[(column - chunk_x) + (row - chunk_y) * size + 1] or 0
            end
        end
        return 0
    end
    return layer.data and layer.data[column + row * width + 1] or 0
end

function EditorMapDocument:setEncodedTile(layer, column, row, encoded, map_id, defer_preview)
    local width, height = self:getTileLayerGridSize(layer, map_id)
    if column < 0 or row < 0 or column >= width or row >= height then return false end
    encoded = encoded or 0
    if self:getEncodedTile(layer, column, row, map_id) == encoded then return false end
    if layer.chunks then
        local size = EditorFormat.CHUNK_SIZE
        local chunk_x, chunk_y = math.floor(column / size) * size, math.floor(row / size) * size
        local chunk, chunk_index
        for index, candidate in ipairs(layer.chunks) do
            if candidate.x == chunk_x and candidate.y == chunk_y then
                chunk, chunk_index = candidate, index
                break
            end
        end
        if not chunk and encoded ~= 0 then
            chunk = { x = chunk_x, y = chunk_y, tile_data = {} }
            for index = 1, size * size do chunk.tile_data[index] = 0 end
            table.insert(layer.chunks, chunk)
        end
        if chunk then
            chunk.tile_data[(column - chunk_x) + (row - chunk_y) * size + 1] = encoded
            if encoded == 0 then
                local empty = true
                for _, tile in ipairs(chunk.tile_data) do
                    if tile ~= 0 then empty = false break end
                end
                if empty then table.remove(layer.chunks, chunk_index) end
            end
        end
    else
        layer.data = layer.data or {}
        for index = #layer.data + 1, width * height do layer.data[index] = 0 end
        layer.data[column + row * width + 1] = encoded
    end
    if not defer_preview then self:invalidatePreview(map_id) end
    return true
end

function EditorMapDocument:encodeTileForLayer(layer, map_id, tileset_id, tile_id)
    if tile_id == nil then return 0 end
    if layer.chunks then
        if layer.tileset and layer.tileset ~= tileset_id then
            return nil, string.format("Layer uses tileset '%s'; select or create a layer for '%s'",
                tostring(layer.tileset), tostring(tileset_id))
        end
        layer.tileset = layer.tileset or tileset_id
        local tileset = Registry.getTileset(tileset_id)
        if tileset then
            layer.tileset_columns = tileset.columns
            layer.tileset_rows = math.ceil((tileset.id_count or tileset.tile_count or 0)
                / math.max(1, tileset.columns))
        end
        return EditorFormat.packTile(tile_id)
    end
    local first_gid = self:getLegacyTilesetFirstGid(map_id, tileset_id)
    if not first_gid then return nil, "Map does not reference tileset '" .. tostring(tileset_id) .. "'" end
    return first_gid + tile_id
end

function EditorMapDocument:getMapAt(world_x, world_y)
    for index = #self.maps, 1, -1 do
        local entry = self.maps[index]
        if world_x >= entry.x and world_y >= entry.y
            and world_x <= entry.x + (entry.width or 0) and world_y <= entry.y + (entry.height or 0) then
            return entry
        end
    end
end

function EditorMapDocument:addEditorObject(event_id, map_id, world_x, world_y, options)
    options = options or {}
    local positioned_entry = self:getMapAt(world_x, world_y)
    map_id = map_id or (positioned_entry and positioned_entry.id) or self.primary_map_id
    local entry = self.map_lookup[map_id]
    local layer = self:getSelectedObjectLayer(map_id)
    if not entry or not layer then return nil, "Select an object layer before placing an event" end
    local free = options.free
    if free == nil then free = Input.ctrl() end
    local tile_width, tile_height = entry.tile_width or 40, entry.tile_height or 40
    local local_x = world_x - entry.x - (layer.offsetx or 0)
    local local_y = world_y - entry.y - (layer.offsety or 0)
    local event_class = Registry.getEditorEvent(event_id)
    local point = event_class and event_class.placement_shape == "point"
    local shape = point and "point" or "rectangle"
    if point then
        if not free then
            local_x = MathUtils.round(local_x / tile_width) * tile_width
            local_y = MathUtils.round(local_y / tile_height) * tile_height
        end
    elseif free then
        local_x = local_x - tile_width / 2
        local_y = local_y - tile_height / 2
    else
        local_x = math.floor(local_x / tile_width) * tile_width
        local_y = math.floor(local_y / tile_height) * tile_height
    end
    local object = {
        type = event_id,
        name = event_id,
        shape = shape,
        x = local_x,
        y = local_y,
        width = point and 0 or tile_width,
        height = point and 0 or tile_height,
        visible = true,
        properties = {},
        __editor_property_types = {}
    }
    self:getObjectId(object)
    layer.objects = layer.objects or {}
    table.insert(layer.objects, object)
    self:invalidatePreview(map_id)
    return object, layer, map_id
end

function EditorMapDocument:addEditorRegion(event_id, map_id, world_x, world_y, width, height)
    local positioned_entry = self:getMapAt(world_x, world_y)
    map_id = map_id or (positioned_entry and positioned_entry.id) or self.primary_map_id
    local entry = self.map_lookup[map_id]
    local layer = self:getSelectedObjectLayer(map_id)
    if not entry or not layer then return nil, "Select an object layer before placing an event" end
    if width <= 0 or height <= 0 then return nil, "Drag a region with a non-zero width and height" end
    local object = {
        type = event_id,
        name = event_id,
        shape = "rectangle",
        x = world_x - entry.x - (layer.offsetx or 0),
        y = world_y - entry.y - (layer.offsety or 0),
        width = width,
        height = height,
        visible = true,
        properties = {},
        __editor_property_types = {}
    }
    self:getObjectId(object)
    layer.objects = layer.objects or {}
    table.insert(layer.objects, object)
    self:invalidatePreview(map_id)
    return object, layer, map_id
end

function EditorMapDocument:addShapeObject(shape, map_id, world_x, world_y, width, height)
    local positioned_entry = self:getMapAt(world_x, world_y)
    map_id = map_id or (positioned_entry and positioned_entry.id) or self.primary_map_id
    local entry = self.map_lookup[map_id]
    local layer = self:getSelectedObjectLayer(map_id)
    if not entry or not layer then return nil, "Select an object layer before creating a shape" end
    local local_x = world_x - entry.x - (layer.offsetx or 0)
    local local_y = world_y - entry.y - (layer.offsety or 0)
    local object = {
        name = shape,
        shape = shape,
        x = local_x,
        y = local_y,
        width = width,
        height = height,
        visible = true,
        properties = {},
        __editor_property_types = {}
    }
    if shape == "line" then object.polyline = { { x = 0, y = 0 }, { x = width, y = height } } end
    self:getObjectId(object)
    layer.objects = layer.objects or {}
    table.insert(layer.objects, object)
    self:invalidatePreview(map_id)
    return object, layer, map_id
end

function EditorMapDocument:addPointShapeObject(shape, map_id, points)
    local minimum = shape == "polygon" and 3 or 2
    if shape ~= "line" and shape ~= "polygon" and shape ~= "polyline" then
        return nil, "Unsupported point shape"
    end
    if not points or #points < minimum then
        return nil, "A " .. shape .. " requires at least " .. minimum .. " points"
    end
    if shape == "line" and #points > 2 then return nil, "A line requires exactly two points" end
    local positioned_entry = self:getMapAt(points[1].x, points[1].y)
    map_id = map_id or (positioned_entry and positioned_entry.id) or self.primary_map_id
    local entry = self.map_lookup[map_id]
    local layer = self:getSelectedObjectLayer(map_id)
    if not entry or not layer then return nil, "Select an object layer before creating a " .. shape end
    local min_x, min_y, max_x, max_y = points[1].x, points[1].y, points[1].x, points[1].y
    for _, point in ipairs(points) do
        min_x, min_y = math.min(min_x, point.x), math.min(min_y, point.y)
        max_x, max_y = math.max(max_x, point.x), math.max(max_y, point.y)
    end
    local object = {
        name = shape,
        shape = shape,
        x = min_x - entry.x - (layer.offsetx or 0),
        y = min_y - entry.y - (layer.offsety or 0),
        width = max_x - min_x,
        height = max_y - min_y,
        visible = true,
        properties = {},
        __editor_property_types = {}
    }
    local points_key = shape == "polygon" and "polygon" or "polyline"
    object[points_key] = {}
    for _, point in ipairs(points) do
        table.insert(object[points_key], { x = point.x - min_x, y = point.y - min_y })
    end
    if shape == "polyline" then
        object.shape_data = { edges = {} }
        for index = 1, #points - 1 do
            table.insert(object.shape_data.edges, { index, index + 1 })
        end
    end
    self:getObjectId(object)
    layer.objects = layer.objects or {}
    table.insert(layer.objects, object)
    self:invalidatePreview(map_id)
    return object, layer, map_id
end

function EditorMapDocument:addPolygonObject(map_id, points)
    return self:addPointShapeObject("polygon", map_id, points)
end

function EditorMapDocument:addPolylineObject(map_id, points)
    return self:addPointShapeObject("polyline", map_id, points)
end

function EditorMapDocument:addLineObject(map_id, points)
    return self:addPointShapeObject("line", map_id, points)
end

function EditorMapDocument:removeEditorObject(selection)
    if not selection or selection.document ~= self then return false end
    for index, object in ipairs(selection.layer.objects or {}) do
        if object == selection.data then
            table.remove(selection.layer.objects, index)
            self:invalidatePreview(selection.map_id)
            return true
        end
    end
    return false
end

function EditorMapDocument:duplicateEditorObject(selection)
    if not selection or selection.document ~= self then return nil end
    local copy = TableUtils.copy(selection.data, true)
    copy.id, copy._editor_uid = nil, nil
    copy.x = (copy.x or 0) + (selection.entry.tile_width or 40)
    self:getObjectId(copy)
    table.insert(selection.layer.objects, copy)
    self:invalidatePreview(selection.map_id)
    return copy, selection.layer
end

function EditorMapDocument:getObjectSelection(map_id, layer, object)
    return {
        document = self,
        world = self.world,
        map_id = map_id,
        entry = self.map_lookup[map_id],
        layer = layer,
        data = object,
        object_id = self:getObjectId(object)
    }
end

function EditorMapDocument:getObjectShape(selection)
    local data = selection and selection.data or {}
    if data.shape == "point" or data.point == true then return "point" end
    if data.polygon then return "polygon" end
    if data.polyline then return data.shape == "polyline" and "polyline" or "line" end
    if data.shape == "ellipse" or data.ellipse == true then return "ellipse" end
    return "rectangle"
end

function EditorMapDocument:getPointShape(selection)
    local data = selection and selection.data
    if not data then return nil end
    return data.polygon
        or (data.shape == "line" or data.shape == "polyline") and data.polyline
end

function EditorMapDocument:getPointShapeWorldPoint(selection, index)
    local points = self:getPointShape(selection)
    local point = points and points[index]
    if not point then return nil end
    local origin_x, origin_y = self:getObjectWorldPosition(selection)
    local rotation = math.rad(selection.data.rotation or 0)
    local x, y = point.x or point[1] or 0, point.y or point[2] or 0
    return origin_x + x * math.cos(rotation) - y * math.sin(rotation),
        origin_y + x * math.sin(rotation) + y * math.cos(rotation)
end

function EditorMapDocument:normalizePointShape(selection)
    local data = selection and selection.data
    local points = self:getPointShape(selection)
    if not points or #points == 0 then return false end
    local min_x, min_y, max_x, max_y
    for _, point in ipairs(points) do
        local x, y = point.x or point[1] or 0, point.y or point[2] or 0
        min_x, min_y = min_x and math.min(min_x, x) or x, min_y and math.min(min_y, y) or y
        max_x, max_y = max_x and math.max(max_x, x) or x, max_y and math.max(max_y, y) or y
    end
    if min_x ~= 0 or min_y ~= 0 then
        local rotation = math.rad(data.rotation or 0)
        data.x = (data.x or 0) + min_x * math.cos(rotation) - min_y * math.sin(rotation)
        data.y = (data.y or 0) + min_x * math.sin(rotation) + min_y * math.cos(rotation)
        for _, point in ipairs(points) do
            point.x = (point.x or point[1] or 0) - min_x
            point.y = (point.y or point[2] or 0) - min_y
            point[1], point[2] = nil, nil
        end
        max_x, max_y = max_x - min_x, max_y - min_y
    end
    data.width, data.height = max_x, max_y
    return true
end

function EditorMapDocument:setPointShapeWorldPoint(selection, index, world_x, world_y)
    local points = self:getPointShape(selection)
    if not selection or selection.document ~= self or not points or not points[index] then return false end
    local origin_x, origin_y = self:getObjectWorldPosition(selection)
    local rotation = -math.rad(selection.data.rotation or 0)
    local dx, dy = world_x - origin_x, world_y - origin_y
    local point = points[index]
    point.x = dx * math.cos(rotation) - dy * math.sin(rotation)
    point.y = dx * math.sin(rotation) + dy * math.cos(rotation)
    point[1], point[2] = nil, nil
    self:normalizePointShape(selection)
    self:invalidatePreview(selection.map_id)
    return true
end

function EditorMapDocument:insertPointShapeWorldPoint(selection, after_index, world_x, world_y)
    local points = self:getPointShape(selection)
    if not selection or selection.document ~= self or not points or not points[after_index] then return false end
    if selection.data.shape == "line" then return false end
    local origin_x, origin_y = self:getObjectWorldPosition(selection)
    local rotation = -math.rad(selection.data.rotation or 0)
    local dx, dy = world_x - origin_x, world_y - origin_y
    local edges = selection.data.shape_data and selection.data.shape_data.edges
    if selection.data.polyline and type(edges) == "table" then
        local remapped = {}
        for _, edge in ipairs(edges) do
            local first, second = tonumber(edge.from or edge[1]), tonumber(edge.to or edge[2])
            if first and second then
                if first == after_index and second == after_index + 1 then
                    table.insert(remapped, { after_index, after_index + 1 })
                    table.insert(remapped, { after_index + 1, after_index + 2 })
                elseif first == after_index + 1 and second == after_index then
                    table.insert(remapped, { after_index + 2, after_index + 1 })
                    table.insert(remapped, { after_index + 1, after_index })
                else
                    table.insert(remapped, {
                        first > after_index and first + 1 or first,
                        second > after_index and second + 1 or second
                    })
                end
            end
        end
        selection.data.shape_data.edges = remapped
    end
    table.insert(points, after_index + 1, {
        x = dx * math.cos(rotation) - dy * math.sin(rotation),
        y = dx * math.sin(rotation) + dy * math.cos(rotation)
    })
    self:normalizePointShape(selection)
    self:invalidatePreview(selection.map_id)
    return after_index + 1
end

function EditorMapDocument:removePointShapePoint(selection, index)
    local points = self:getPointShape(selection)
    local minimum = selection and selection.data and selection.data.polygon and 3 or 2
    if not selection or selection.document ~= self or not points
        or #points <= minimum or not points[index] then return false end
    local edges = selection.data.shape_data and selection.data.shape_data.edges
    if selection.data.polyline and type(edges) == "table" then
        local remapped, neighbors = {}, {}
        for _, edge in ipairs(edges) do
            local first, second = tonumber(edge.from or edge[1]), tonumber(edge.to or edge[2])
            if first == index or second == index then
                table.insert(neighbors, first == index and second or first)
            elseif first and second then
                table.insert(remapped, {
                    first > index and first - 1 or first,
                    second > index and second - 1 or second
                })
            end
        end
        if #neighbors == 2 then
            local first = neighbors[1] > index and neighbors[1] - 1 or neighbors[1]
            local second = neighbors[2] > index and neighbors[2] - 1 or neighbors[2]
            if first ~= second then table.insert(remapped, { first, second }) end
        end
        selection.data.shape_data.edges = remapped
    end
    table.remove(points, index)
    self:normalizePointShape(selection)
    self:invalidatePreview(selection.map_id)
    return true
end

function EditorMapDocument:getPolygonWorldPoint(selection, index)
    return self:getPointShapeWorldPoint(selection, index)
end

function EditorMapDocument:normalizePolygon(selection)
    return self:normalizePointShape(selection)
end

function EditorMapDocument:setPolygonWorldPoint(selection, index, world_x, world_y)
    return self:setPointShapeWorldPoint(selection, index, world_x, world_y)
end

function EditorMapDocument:insertPolygonWorldPoint(selection, after_index, world_x, world_y)
    return self:insertPointShapeWorldPoint(selection, after_index, world_x, world_y)
end

function EditorMapDocument:removePolygonPoint(selection, index)
    return self:removePointShapePoint(selection, index)
end

function EditorMapDocument:setObjectShape(selection, shape)
    if not selection or selection.document ~= self then return false end
    if shape ~= "point" and shape ~= "rectangle" and shape ~= "ellipse"
        and shape ~= "line" and shape ~= "polygon" and shape ~= "polyline" then return false end
    local data = selection.data
    local previous_shape = self:getObjectShape(selection)
    if previous_shape == shape and data.shape == shape then return false end
    local tile_width = selection.entry and selection.entry.tile_width or 40
    local tile_height = selection.entry and selection.entry.tile_height or 40
    local previous_width, previous_height = data.width or 0, data.height or 0
    local rotation = math.rad(data.rotation or 0)
    if previous_shape ~= shape then data.shape_data = {} end
    if shape == "point" and previous_shape ~= "point" then
        data.x = (data.x or 0) + previous_width / 2 * math.cos(rotation)
            - previous_height / 2 * math.sin(rotation)
        data.y = (data.y or 0) + previous_width / 2 * math.sin(rotation)
            + previous_height / 2 * math.cos(rotation)
    end
    data.shape = shape
    data.point, data.ellipse = nil, nil
    if shape == "point" then
        data.width, data.height = 0, 0
        data.polygon, data.polyline = nil, nil
    else
        if (data.width or 0) <= 0 then data.width = tile_width end
        if (data.height or 0) <= 0 then data.height = tile_height end
        if previous_shape == "point" then
            data.x = (data.x or 0) - data.width / 2 * math.cos(rotation)
                + data.height / 2 * math.sin(rotation)
            data.y = (data.y or 0) - data.width / 2 * math.sin(rotation)
                - data.height / 2 * math.cos(rotation)
        end
        if shape == "line" or shape == "polyline" then
            if not data.polyline then
                data.polyline = { { x = 0, y = 0 }, { x = data.width, y = data.height } }
            end
            if shape == "line" and #data.polyline > 2 then
                data.polyline = { data.polyline[1], data.polyline[#data.polyline] }
            end
            if shape == "polyline" then
                data.shape_data.edges = {}
                for index = 1, #data.polyline - 1 do
                    table.insert(data.shape_data.edges, { index, index + 1 })
                end
            end
            data.polygon = nil
        elseif shape == "polygon" then
            if previous_shape ~= "polygon" or not data.polygon then
                data.polygon = {
                    { x = 0, y = 0 }, { x = data.width, y = 0 },
                    { x = data.width, y = data.height }, { x = 0, y = data.height }
                }
            end
            data.polyline = nil
        else
            data.polygon, data.polyline = nil, nil
        end
    end
    self:invalidatePreview(selection.map_id)
    return true
end

function EditorMapDocument:findObjectAt(world_x, world_y, options)
    options = options or {}
    for entry_index = #self.maps, 1, -1 do
        local entry = self.maps[entry_index]
        local layers = self:getFlatEditableLayers(entry.id, false)
        for layer_index = #layers, 1, -1 do
            local layer_entry = layers[layer_index]
            local layer = layer_entry.layer
            local layer_type = Registry.getLayerType(layer._editor_type_id)
            if layer_entry.visible and layer_type and layer_type.kind == "object"
                and (options.all_layers or self:isLayerSelectable(layer, entry.id)) then
                local x = world_x - entry.x - (layer.offsetx or 0)
                local y = world_y - entry.y - (layer.offsety or 0)
                for object_index = #(layer.objects or {}), 1, -1 do
                    local object = layer.objects[object_index]
                    local selection = self:getObjectSelection(entry.id, layer, object)
                    local object_x, object_y, width, height = self:getObjectLocalRect(selection)
                    local dx, dy = x - object_x, y - object_y
                    local rotation = -math.rad(object.rotation or 0)
                    local local_x = dx * math.cos(rotation) - dy * math.sin(rotation)
                    local local_y = dx * math.sin(rotation) + dy * math.cos(rotation)
                    local hit = width == 0 and height == 0
                        and math.abs(local_x) <= 10 and math.abs(local_y) <= 10
                        or local_x >= 0 and local_y >= 0 and local_x <= width and local_y <= height
                    if object.polyline and #object.polyline >= 2 then
                        hit = false
                        local thickness = object.shape_data and tonumber(object.shape_data.thickness) or 0
                        local tolerance = math.max(10, thickness / 2 + 4)
                        for _, edge in ipairs(MapUtils.getPolylineEdges(object, #object.polyline)) do
                            local first, second = object.polyline[edge[1]], object.polyline[edge[2]]
                            local x1, y1 = first.x or first[1] or 0, first.y or first[2] or 0
                            local x2, y2 = second.x or second[1] or 0, second.y or second[2] or 0
                            local vx, vy = x2 - x1, y2 - y1
                            local length_squared = vx * vx + vy * vy
                            local amount = length_squared == 0 and 0
                                or math.max(0, math.min(1, ((local_x - x1) * vx + (local_y - y1) * vy) / length_squared))
                            local nearest_x, nearest_y = x1 + vx * amount, y1 + vy * amount
                            local distance_x, distance_y = local_x - nearest_x, local_y - nearest_y
                            if distance_x * distance_x + distance_y * distance_y <= tolerance * tolerance then
                                hit = true
                                break
                            end
                        end
                    end
                    if hit then return selection end
                end
            end
        end
    end
end

function EditorMapDocument:addTileObject(tileset_id, tile_id, map_id, world_x, world_y)
    local positioned_entry = self:getMapAt(world_x, world_y)
    map_id = map_id or (positioned_entry and positioned_entry.id) or self.primary_map_id
    local entry = self.map_lookup[map_id]
    local layer = self:getSelectedObjectLayer(map_id)
    local tileset = Registry.getTileset(tileset_id)
    if not entry or not layer then return nil, "Select an object layer before placing a tile object" end
    if not tileset then return nil, "Unknown tileset '" .. tostring(tileset_id) .. "'" end
    local width, height = tileset:getTileSize(tile_id)
    local local_x = world_x - entry.x - (layer.offsetx or 0)
    local local_y = world_y - entry.y - (layer.offsety or 0)
    if not Input.ctrl() then
        local grid_width, grid_height = entry.tile_width or 40, entry.tile_height or 40
        local_x = math.floor(local_x / grid_width) * grid_width
        local_y = math.floor(local_y / grid_height) * grid_height
    else
        local_x, local_y = local_x - width / 2, local_y - height / 2
    end
    local origin = Tileset.ORIGINS[tileset.object_alignment] or Tileset.ORIGINS.unspecified
    local object = {
        name = "", type = "", tileset = tileset_id, tile_id = tile_id,
        x = local_x + origin[1] * width, y = local_y + origin[2] * height,
        width = width, height = height, rotation = 0, visible = true,
        properties = {}, __editor_property_types = {}
    }
    self:getObjectId(object)
    layer.objects = layer.objects or {}
    table.insert(layer.objects, object)
    self:invalidatePreview(map_id)
    return object, layer, map_id
end

function EditorMapDocument:getObjectLocalRect(selection)
    local data = selection.data
    if data.gid then
        local preview = self:getPreview(selection.entry)
        if preview and preview.map then return preview.map:getTileObjectRect(data) end
    elseif data.tileset and data.tile_id ~= nil then
        local tileset = Registry.getTileset(data.tileset)
        if tileset then
            local tile_width, tile_height = tileset:getTileSize(data.tile_id)
            local width, height = data.width or tile_width, data.height or tile_height
            local origin = Tileset.ORIGINS[tileset.object_alignment] or Tileset.ORIGINS.unspecified
            return (data.x or 0) - origin[1] * width,
                (data.y or 0) - origin[2] * height, width, height
        end
    end
    local width, height = data.width or 0, data.height or 0
    if self:getObjectScalingMode(selection) == "scale" then
        width = width * math.abs(data.scale_x or 1)
        height = height * math.abs(data.scale_y or 1)
    end
    return data.x or 0, data.y or 0, width, height
end

function EditorMapDocument:getEditorObjectType(data, map_id)
    local event_type = data and data.type
    local reader = map_id and Registry.getMapReader(map_id)
    if reader and reader.LEGACY_FORMAT and (event_type == nil or event_type == "") then
        event_type = data.class
        if event_type == nil or event_type == "" then event_type = data.name end
    end
    return type(event_type) == "string" and event_type:lower() or event_type
end

function EditorMapDocument:getObjectScalingMode(selection)
    local data = selection and selection.data
    if not data or data.gid or data.tileset and data.tile_id ~= nil then return "resize" end
    local event_type = self:getEditorObjectType(data, selection.map_id)
    local event_class = event_type and Registry.getEditorEvent(event_type)
    return event_class and event_class.scaling_mode or EditorEvent.scaling_mode
end

function EditorMapDocument:getObjectWorldCorners(selection)
    local x, y = self:getObjectWorldPosition(selection)
    local _, _, width, height = self:getObjectLocalRect(selection)
    local rotation = math.rad(selection.data.rotation or 0)
    local cosine, sine = math.cos(rotation), math.sin(rotation)
    local result = {}
    for _, point in ipairs({ { 0, 0 }, { width, 0 }, { width, height }, { 0, height } }) do
        table.insert(result, {
            x = x + point[1] * cosine - point[2] * sine,
            y = y + point[1] * sine + point[2] * cosine
        })
    end
    return result
end

function EditorMapDocument:getObjectWorldBounds(selection)
    local corners = self:getObjectWorldCorners(selection)
    local min_x, min_y, max_x, max_y = corners[1].x, corners[1].y, corners[1].x, corners[1].y
    for index = 2, #corners do
        local point = corners[index]
        min_x, min_y = math.min(min_x, point.x), math.min(min_y, point.y)
        max_x, max_y = math.max(max_x, point.x), math.max(max_y, point.y)
    end
    return min_x, min_y, max_x, max_y
end

function EditorMapDocument:findObjectsInRect(x1, y1, x2, y2, options)
    options = options or {}
    local min_x, min_y, max_x, max_y = math.min(x1, x2), math.min(y1, y2), math.max(x1, x2), math.max(y1, y2)
    local result = {}
    for _, entry in ipairs(self.maps) do
        for _, layer_entry in ipairs(self:getFlatEditableLayers(entry.id, false)) do
            local layer = layer_entry.layer
            local layer_type = Registry.getLayerType(layer._editor_type_id)
            if layer_entry.visible and layer_type and layer_type.kind == "object"
                and (options.all_layers or self:isLayerSelectable(layer, entry.id)) then
                for _, object in ipairs(layer.objects or {}) do
                    if object.visible ~= false then
                        local selection = self:getObjectSelection(entry.id, layer, object)
                        local left, top, right, bottom = self:getObjectWorldBounds(selection)
                        if right >= min_x and bottom >= min_y and left <= max_x and top <= max_y then
                            table.insert(result, selection)
                        end
                    end
                end
            end
        end
    end
    return result
end

function EditorMapDocument:getObjectWorldPosition(selection)
    local data, layer, entry = selection.data, selection.layer, selection.entry
    local x, y = self:getObjectLocalRect(selection)
    return entry.x + (layer.offsetx or 0) + x,
        entry.y + (layer.offsety or 0) + y
end

function EditorMapDocument:getObjectWorldCenter(selection)
    local x, y = self:getObjectWorldPosition(selection)
    local _, _, width, height = self:getObjectLocalRect(selection)
    local half_width, half_height = width / 2, height / 2
    local rotation = math.rad(selection.data.rotation or 0)
    return x + half_width * math.cos(rotation) - half_height * math.sin(rotation),
        y + half_width * math.sin(rotation) + half_height * math.cos(rotation)
end

function EditorMapDocument:createObjectReference(selection)
    return self.world:createReference(selection.map_id, selection.object_id)
end

function EditorMapDocument:resolveObjectReference(value)
    local reference = EditorObjectReference.from(value, self.primary_map_id)
    if reference.object_id == nil then return nil end
    local map_id = reference.map_id or self.primary_map_id
    if not map_id or not self.map_lookup[map_id] then return nil end
    local layers = self:getAllEditableLayers(map_id)
    for _, layer in ipairs(layers) do
        for _, object in ipairs(layer.objects or {}) do
            if tostring(self:getObjectId(object)) == tostring(reference.object_id) then
                return self:getObjectSelection(map_id, layer, object)
            end
        end
    end
end

function EditorMapDocument:addObjectFX(selection, fx_id)
    if not selection or selection.document ~= self or not Registry.getEditorDrawFX(fx_id) then return false end
    selection.data.__editor_fx = selection.data.__editor_fx or {}
    local fx = Registry.createEditorDrawFX(fx_id)
    table.insert(selection.data.__editor_fx, fx.data)
    return fx
end

function EditorMapDocument:getObjectReferenceValues(selection)
    local data = selection.data
    local event_id = self:getEditorObjectType(data, selection.map_id)
    local result = {}
    local success, event = pcall(Registry.createEditorEvent, event_id, data, { map_id = selection.map_id })
    if success and event then
        for _, definition in ipairs(event.property_set:getProperties()) do
            if definition.type == "object_reference" or definition.type == "marker_reference" then
                local value = event.property_set.values[definition.id]
                if value ~= nil then table.insert(result, value) end
            end
        end
    end
    for name, type_id in pairs(data.__editor_property_types or {}) do
        if (type_id == "object_reference" or type_id == "marker_reference")
            and data.properties[name] ~= nil then
            table.insert(result, data.properties[name])
        end
    end
    return result
end

function EditorMapDocument:findMarkerSelection(map_id, marker)
    local reference = EditorObjectReference.from(marker, map_id)
    map_id = reference.map_id or map_id
    if not self.map_lookup[map_id] or reference.object_id == nil then return nil end
    for _, layer_entry in ipairs(self:getFlatEditableLayers(map_id, false)) do
        local layer = layer_entry.layer
        local marker_layer = layer._editor_type_id == "markers" or layer.type == "markers"
            or tostring(layer.name or ""):lower() == "markers"
        if marker_layer then
            for _, object in ipairs(layer.objects or {}) do
                if tostring(object.id) == tostring(reference.object_id)
                    or tostring(object.name) == tostring(reference.object_id) then
                    return self:getObjectSelection(map_id, layer, object)
                end
            end
        end
    end
end

function EditorMapDocument:getTransitionLink(selection)
    if self:getEditorObjectType(selection.data, selection.map_id) ~= "transition" then return nil end
    local properties = selection.data.properties or {}
    local target_map = properties.map
    local target_entry = target_map and self.map_lookup[target_map]
    if not target_entry then return nil end

    local arrival = properties.marker and self:findMarkerSelection(target_map, properties.marker) or nil
    local arrival_x, arrival_y
    if arrival then
        arrival_x, arrival_y = self:getObjectWorldCenter(arrival)
    elseif tonumber(properties.x) and tonumber(properties.y) then
        arrival_x = target_entry.x + tonumber(properties.x)
        arrival_y = target_entry.y + tonumber(properties.y)
    end

    local reciprocal, reciprocal_distance
    for _, layer in ipairs(self:getAllEditableLayers(target_map)) do
        for _, object in ipairs(layer.objects or {}) do
            if self:getEditorObjectType(object, target_map) == "transition"
                and object.properties and object.properties.map == selection.map_id then
                local candidate = self:getObjectSelection(target_map, layer, object)
                local x, y = self:getObjectWorldCenter(candidate)
                local distance = arrival_x and ((x - arrival_x) ^ 2 + (y - arrival_y) ^ 2) or 0
                if not reciprocal or distance < reciprocal_distance then
                    reciprocal, reciprocal_distance = candidate, distance
                end
            end
        end
    end
    if reciprocal then return reciprocal end
    if arrival then return arrival end
    return {
        map_id = target_map,
        entry = target_entry,
        object_id = "transition_destination",
        world_x = arrival_x or target_entry.x + (target_entry.width or 0) / 2,
        world_y = arrival_y or target_entry.y + (target_entry.height or 0) / 2
    }
end

function EditorMapDocument:getObjectLinks(selection)
    local links, seen = {}, {}
    local function add(candidate)
        if candidate and candidate.data ~= selection.data then
            local map_id = candidate.map_id or candidate.entry and candidate.entry.id
                or self.primary_map_id
            if not map_id or candidate.object_id == nil then return end
            candidate.map_id = map_id
            candidate.entry = candidate.entry or self.map_lookup[map_id]
            if not candidate.entry then return end
            local key = map_id .. ":" .. tostring(candidate.object_id)
            if not seen[key] then seen[key] = true table.insert(links, candidate) end
        end
    end
    add(self:getTransitionLink(selection))
    for _, value in ipairs(self:getObjectReferenceValues(selection)) do add(self:resolveObjectReference(value)) end
    for _, entry in ipairs(self.maps) do
        for _, layer in ipairs(self:getAllEditableLayers(entry.id)) do
            for _, object in ipairs(layer.objects or {}) do
                if object ~= selection.data then
                    local candidate = self:getObjectSelection(entry.id, layer, object)
                    for _, value in ipairs(self:getObjectReferenceValues(candidate)) do
                        local reference = EditorObjectReference.from(value, entry.id)
                        if reference:matches(selection.map_id, selection.object_id) then add(candidate) end
                    end
                end
            end
        end
    end
    return links
end

function EditorMapDocument:createPreview(entry)
    local data = Registry.getMapData(entry.id)
    if not data then return nil, "no registered map data is available" end

    local root = Object()
    local map = Map(root, data)
    map.id = entry.id
    local depth = map.depth_per_layer
    local editor_events = {}
    local editor_overlays = {}
    local drawable_layers = {}
    local layer_lookup = {}
    local layer_visibility = {}
    local layer_parent = {}
    local layer_registry = Registry.layer_types
    local reader_class = Registry.getMapReader(entry.id)
    for _, tree_entry in ipairs(self:getFlatEditableLayers(entry.id, false)) do
        local layer = tree_entry.layer
        layer_lookup[layer._editor_uid] = layer
        layer_visibility[layer._editor_uid] = tree_entry.visible
        layer_parent[layer._editor_uid] = tree_entry.parent and tree_entry.parent._editor_uid or false
        local layer_depth = layer._editor_depth_override or depth
        map.layers[layer.name] = layer_depth
        if layer._editor_kind_id == "group" then
            -- no-op
        elseif layer.type == "tilelayer" then
            map:loadTiles(layer, layer_depth)
            local drawable = map.tile_layers[#map.tile_layers]
            drawable.visible = true
            drawable_layers[drawable] = layer._editor_uid
        elseif layer.type == "imagelayer" and layer.image then
            map:loadImage(layer, layer_depth)
            local drawable = map.image_layers[layer.name]
            drawable.visible = true
            drawable_layers[drawable] = layer._editor_uid
        elseif layer.type == "objectgroup" then
            local layer_type = layer_registry:get(layer._editor_type_id)
                or (reader_class and reader_class.LEGACY_FORMAT and layer_registry:getLegacyTiledType(layer))
            if layer_type and (layer_type.id == "objects" or layer_type.id == "controllers") then
                local layer_color = layer_registry:getLayerColor(layer, layer_type)
                for _, object in ipairs(layer.objects or {}) do
                    local event_id = self:getEditorObjectType(object, entry.id)
                    table.insert(editor_events, Registry.createEditorEvent(event_id, object, {
                        depth = layer_depth,
                        layer_uid = layer._editor_uid,
                        layer = layer,
                        layer_type = layer_type,
                        layer_color = layer_color,
                        offset_x = layer.offsetx or 0,
                        offset_y = layer.offsety or 0,
                        map_id = entry.id,
                        map_data = data,
                        map = map
                    }))
                end
            elseif layer_type then
                table.insert(editor_overlays, EditorLayerOverlay(layer, layer_type, layer_depth))
            end
        end
        if layer._editor_kind_id ~= "group" and not layer.properties.thin then
            depth = depth + map.depth_per_layer
        end
    end
    root:updateChildList()
    entry.width = map.width * map.tile_width
    entry.height = map.height * map.tile_height
    entry.tile_width = map.tile_width
    entry.tile_height = map.tile_height
    return {
        root = root,
        map = map,
        editor_events = editor_events,
        editor_overlays = editor_overlays,
        drawable_layers = drawable_layers,
        layer_lookup = layer_lookup,
        layer_visibility = layer_visibility,
        layer_parent = layer_parent
    }
end

function EditorMapDocument:getPreview(entry)
    if entry.preview_attempted then return entry.preview end
    entry.preview_attempted = true
    local success, preview, reason = pcall(function()
        local result, failure = self:createPreview(entry)
        return result, failure
    end)
    if success then
        entry.preview = preview
        reason = reason or (not preview and "preview creation failed")
    else
        reason = preview
    end
    if not entry.preview and self.editor then
        self.editor:addWarning(string.format("Could not preview map '%s': %s", entry.id, reason),
            nil, "map_preview:" .. entry.id)
    end
    return entry.preview
end

function EditorMapDocument:drawPreview(entry, outline_width)
    local preview = self:getPreview(entry)
    if not preview then return false end
    local map = preview.map
    Draw.setColor(map.bg_color or { 0, 0, 0, 0 })
    love.graphics.rectangle("fill", 0, 0, entry.width, entry.height)
    Draw.setColor(1, 1, 1, 1)
    local drawables = {}
    local selected_uid = self:getSelectedLayer(entry.id)
    local function layerState(uid)
        local layer = uid and preview.layer_lookup[uid]
        if layer and (layer._editor_visible == false or preview.layer_visibility[uid] == false) then return false, 0 end
        local darken = not self.editor or self.editor.darken_unselected_layers ~= false
        local selected = selected_uid == nil or selected_uid == uid
        local parent_uid = uid and preview.layer_parent[uid]
        while not selected and parent_uid do
            selected = selected_uid == parent_uid
            parent_uid = preview.layer_parent[parent_uid]
        end
        return true, (not darken or selected) and 1 or 0.35
    end
    for index, child in ipairs(preview.root.children) do
        local uid = preview.drawable_layers[child]
        local layer_visible, alpha = layerState(uid)
        if child.visible and child.parent == preview.root and layer_visible then
            table.insert(drawables, {
                layer = child.layer or 0, index = index, value = child, object = true, alpha = alpha
            })
        end
    end
    local offset = #drawables
    for index, event in ipairs(preview.editor_events or {}) do
        local layer_visible, alpha = layerState(event.layer_uid)
        if event.visible and layer_visible then
            table.insert(drawables, { layer = event.layer or 0, index = offset + index, value = event, alpha = alpha })
        end
    end
    offset = offset + #(preview.editor_events or {})
    for index, overlay in ipairs(preview.editor_overlays or {}) do
        local layer_visible, alpha = layerState(overlay.layer_uid)
        if overlay.visible and layer_visible then
            table.insert(drawables, {
                layer = overlay.layer or 0, index = offset + index, value = overlay, alpha = alpha
            })
        end
    end
    table.sort(drawables, function(a, b)
        if a.layer == b.layer then return a.index < b.index end
        return a.layer < b.layer
    end)
    for _, drawable in ipairs(drawables) do
        if drawable.object then
            local old_alpha = drawable.value.alpha
            drawable.value.alpha = (old_alpha or 1) * drawable.alpha
            drawable.value:fullDraw()
            drawable.value.alpha = old_alpha
        else
            drawable.value:draw(drawable.alpha, outline_width)
        end
    end
    for _, event in ipairs(preview.editor_events or {}) do
        local layer_visible, alpha = layerState(event.layer_uid)
        if event.visible and layer_visible then event:drawBounds(alpha, outline_width) end
    end
    Draw.setColor(1, 1, 1, 1)
    return true
end

return EditorMapDocument
