---@class TiledTilesetReader : TilesetReader
---@overload fun(tileset: Tileset): TiledTilesetReader
local TiledTilesetReader, super = Class(TilesetReader)

TiledTilesetReader.FORMAT = "tiled"
TiledTilesetReader.LEGACY_FORMAT = true

local operations = {}
TiledTilesetReader.operations = operations

function TiledTilesetReader:initialize(data, path, base_dir)
    local tileset = self.tileset

    tileset.data = data

    tileset.path = path
    tileset.base_dir = base_dir or FileSystemUtils.getDirname(tileset.path)

    tileset.id = data.id
    tileset.name = data.name
    tileset.tile_count = data.tilecount or 0
    tileset.tile_width = data.tilewidth or 40
    tileset.tile_height = data.tileheight or 40
    tileset.margin = data.margin or 0
    tileset.spacing = data.spacing or 0
    tileset.columns = data.columns or 0
    tileset.object_alignment = data.objectalignment or "unspecified"
    tileset.fill_grid = data.tilerendersize == "grid"
    tileset.preserve_aspect_fit = data.fillmode == "preserve-aspect-fit"

    tileset.id_count = tileset.tile_count

    tileset.tile_info = {}
    for _, tile in ipairs(data.tiles or {}) do
        local info = {}
        info.properties = tile.properties or {}
        info.probability = tile.probability
        info.class = tile.class or tile.type
        info.objectgroup = tile.objectgroup
        info.terrain = tile.terrain
        if tile.animation then
            info.animation = { duration = 0, frames = {} }
            for _, anim in ipairs(tile.animation) do
                table.insert(info.animation.frames, { id = anim.tileid, duration = anim.duration / 1000 })
                info.animation.duration = info.animation.duration + (anim.duration / 1000)
            end
        end
        if tile.image then
            local success, image_path_result = tileset:loadTextureFromImagePath(tile.image)
            if not success then
                error("Tileset \"" .. tileset.id .. "\" failed to load texture for tile " .. tostring(tile.id) .. "\"\n" .. image_path_result)
            end
            info.path = image_path_result
            info.texture = Assets.getTexture(image_path_result)
            info.x = tile.x or 0
            info.y = tile.y or 0
            info.width = tile.width or info.texture:getWidth()
            info.height = tile.height or info.texture:getHeight()

            if info.x ~= 0 or info.y ~= 0 or info.width ~= info.texture:getWidth() or info.height ~= info.texture:getHeight() then
                info.quad = love.graphics.newQuad(info.x, info.y, info.width, info.height, info.texture:getWidth(), info.texture:getHeight())
            end
        end
        tileset.tile_info[tile.id] = info
        tileset.id_count = math.max(tileset.id_count, tile.id + 1)
    end

    if data.image then
        local success, image_path_result = tileset:loadTextureFromImagePath(data.image)
        if not success then
            error("Tileset \"" .. tileset.id .. "\" failed to load texture\n" .. image_path_result)
        end
        tileset.texture = Assets.getTexture(image_path_result)
    end

    tileset.quads = {}
    if tileset.texture then
        local tw, th = tileset.texture:getWidth(), tileset.texture:getHeight()
        for i = 0, tileset.tile_count - 1 do
            local tx = tileset.margin + (i % tileset.columns) * (tileset.tile_width + tileset.spacing)
            local ty = tileset.margin + math.floor(i / tileset.columns) * (tileset.tile_height + tileset.spacing)
            tileset.quads[i] = love.graphics.newQuad(tx, ty, tileset.tile_width, tileset.tile_height, tw, th)
        end
    end
end

--- Always saves as the editor format, cause i don't really wanna write a legacy saver...
function TiledTilesetReader:save(path, options)
    local data, reason = EditorTilesetReader.convertLegacyData(self.tileset.data, options)
    if not data then return false, reason end
    return EditorTilesetReader.saveData(data, path, options)
end

function operations.loadTextureFromImagePath(tileset, filename)
    local image_dir = "assets/sprites"
    local success, result, final_path = TiledUtils.relativePathToAssetId(image_dir, filename, tileset.base_dir)

    if not success then
        if result == "not under prefix" then
            return false, "Image not found in \"" .. image_dir .. "\" (Got path \"" .. final_path .. "\")"
        elseif result == "path outside root" then
            return false, "Image path located outside Kristal (Got path \"<kristal>/" .. final_path .. "\")"
        else
            return false, "Unknown reason"
        end
    end

    local texture = Assets.getTexture(result)

    if not texture then
        return false, "No texture found with id \"" .. result .. "\""
    end

    return true, result
end

return TiledTilesetReader
