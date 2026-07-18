--- Builds serializable editor format data from open documents.
---@class EditorFormatDocument
local EditorFormatDocument = {}

function EditorFormatDocument.getMapContext(document, map_id)
    map_id = map_id or document.primary_map_id
    if not map_id then return nil, "Map document has no primary map" end
    local source_data = Registry.getMapData(map_id)
    return {
        id = map_id,
        document = document,
        source_data = source_data,
        layers = document:getEditableLayers(map_id),
        world = document.world,
        world_entry = document.map_lookup and document.map_lookup[map_id],
        grid_width = source_data and (source_data.grid_width or source_data.tilewidth),
        grid_height = source_data and (source_data.grid_height or source_data.tileheight)
    }
end

function EditorFormatDocument.getTilesetContext(document)
    return {
        id = document.id,
        document = document,
        data = document.data,
        runtime_tileset = document.tileset
    }
end

function EditorFormatDocument.buildMapData(document, map_id, options)
    local context, reason = EditorFormatDocument.getMapContext(document, map_id)
    if not context then return nil, reason end
    local data = TableUtils.copy(context.source_data or {}, true)
    data.id = context.id
    data.width = data.width or 16
    data.height = data.height or 12
    data.grid_width = context.grid_width or data.grid_width or data.tilewidth or 40
    data.grid_height = context.grid_height or data.grid_height or data.tileheight or 40
    data.layers = context.layers
    local reader = Registry.getMapReader(context.id)
    if reader and reader.LEGACY_FORMAT then
        return TiledEditorFormatConverter.convertMap(data, options)
    end
    MapUtils.walkObjects(data.layers, function(object)
        Registry.createEditorEvent(object.type, object, { map_id = context.id })
    end)
    return data
end

function EditorFormatDocument.buildTilesetData(document)
    local context = EditorFormatDocument.getTilesetContext(document)
    local data = TableUtils.copy(context.data or {}, true)
    data.id = context.id
    return data
end

function EditorFormatDocument.buildWorldData(world)
    local data = TableUtils.copy(world.data or {}, true)
    data.id = world.id or data.id
    data.name = world.name or data.name
    data.properties = world.properties or data.properties or {}
    data.__editor_property_types = world.__editor_property_types or data.__editor_property_types
    data.maps = {}
    for _, entry in ipairs(world.maps or {}) do
        table.insert(data.maps, { map = entry.id, x = entry.x or 0, y = entry.y or 0 })
    end
    return data
end

function EditorFormatDocument.saveMap(document, path, options, map_id)
    local data, reason = EditorFormatDocument.buildMapData(document, map_id, options)
    if not data then return false, reason end
    return EditorFormat.saveMapData(data, path, options)
end

function EditorFormatDocument.saveTileset(document, path, options)
    local data, reason = EditorFormatDocument.buildTilesetData(document)
    if not data then return false, reason end
    return EditorFormat.saveTilesetData(data, path, options)
end

function EditorFormatDocument.saveWorld(world, path, options)
    return EditorFormat.saveWorldData(EditorFormatDocument.buildWorldData(world), path, options)
end

return EditorFormatDocument
