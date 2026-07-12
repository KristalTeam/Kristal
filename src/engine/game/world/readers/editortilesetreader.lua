---@class EditorTilesetReader : TilesetReader
---@overload fun(tileset: Tileset): EditorTilesetReader
local EditorTilesetReader, super = Class(TilesetReader)

EditorTilesetReader.FORMAT = "editor"
EditorTilesetReader.LEGACY_FORMAT = false
EditorTilesetReader.operations = {}

function EditorTilesetReader:initialize(data, path, base_dir)
    local tileset = self.tileset
    tileset.data = data
    tileset.path = path
    tileset.base_dir = base_dir or FileSystemUtils.getDirname(path)
    tileset.id = data.id
    tileset.name = data.name
    tileset.tile_count = data.tile_count or 0
    tileset.tile_width = data.tile_width or 40
    tileset.tile_height = data.tile_height or 40
    tileset.margin = data.margin or 0
    tileset.spacing = data.spacing or 0
    tileset.columns = math.max(1, data.tile_columns or 1)
    tileset.object_alignment = data.alignment or "unspecified"
    tileset.fill_grid = data.render_size == "grid"
    tileset.preserve_aspect_fit = data.fill_mode == "preserve-aspect-fit"
    tileset.id_count = tileset.tile_count
    tileset.tile_info = {}

    local function loadTileTexture(info, filename, id)
        local success, texture_id = tileset:loadTextureFromImagePath(filename)
        if not success then return false, texture_id end
        info.path = texture_id
        info.texture = Assets.getTexture(texture_id)
        if not info.texture then return false, "No texture found for tile " .. tostring(id) end
        info.width = info.width or info.texture:getWidth()
        info.height = info.height or info.texture:getHeight()
        return true
    end

    for _, tile in ipairs(data.tiles or {}) do
        local info = {
            properties = tile.properties or {},
            probability = tile.probability,
            class = tile.type,
            objectgroup = tile.objectgroup
        }
        if tile.frames or tile.animation then
            info.animation = { duration = 0, frames = {} }
            for _, frame in ipairs(tile.frames or tile.animation) do
                local duration = (frame.duration or 0) / EditorFormat.MILLISECONDS_PER_SECOND
                table.insert(info.animation.frames, { id = frame.tile_id or frame.tileid, duration = duration })
                info.animation.duration = info.animation.duration + duration
            end
        end
        if tile.image then
            info.x, info.y = tile.x or 0, tile.y or 0
            info.width, info.height = tile.width, tile.height
            local success, reason = loadTileTexture(info, tile.image, tile.id)
            if not success then error(reason, 2) end
        end
        tileset.tile_info[tile.id] = info
        tileset.id_count = math.max(tileset.id_count, tile.id + 1)
    end

    if type(data.image) == "string" then
        local success, texture_id = tileset:loadTextureFromImagePath(data.image)
        if not success then error(texture_id, 2) end
        tileset.texture = Assets.getTexture(texture_id)
    elseif type(data.image) == "table" then
        for index, filename in ipairs(data.image) do
            local id = index - 1
            local info = tileset.tile_info[id] or { properties = {} }
            local success, reason = loadTileTexture(info, filename, id)
            if not success then error(reason, 2) end
            tileset.tile_info[id] = info
            tileset.id_count = math.max(tileset.id_count, id + 1)
        end
    end

    tileset.quads = {}
    if tileset.texture then
        local texture_width, texture_height = tileset.texture:getWidth(), tileset.texture:getHeight()
        for id = 0, tileset.tile_count - 1 do
            local x = tileset.margin + (id % tileset.columns) * (tileset.tile_width + tileset.spacing)
            local y = tileset.margin + math.floor(id / tileset.columns) * (tileset.tile_height + tileset.spacing)
            tileset.quads[id] = love.graphics.newQuad(x, y, tileset.tile_width, tileset.tile_height,
                texture_width, texture_height)
        end
    end
    return true
end

function EditorTilesetReader.operations.loadTextureFromImagePath(tileset, filename)
    local texture, resolved_id = Assets.resolveTextureReference(filename)
    if texture then return true, resolved_id end
    return false, "Could not resolve tileset image asset '" .. tostring(filename) .. "'"
end

function EditorTilesetReader.convertLegacyData(data, options)
    return TiledEditorFormatConverter.convertTileset(data, options)
end

function EditorTilesetReader.saveData(data, path, options)
    return EditorFormat.saveTilesetData(data, path, options)
end

function EditorTilesetReader:save(path, options)
    return EditorFormat.saveTilesetData(self.tileset.data, path, options)
end

return EditorTilesetReader
