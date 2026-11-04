--- Defines shared operations for loading tileset data.\
--- Currently implemented by the Tiled legacy set and the new Editor format set.
---@class TilesetReader : Class
---@overload fun(tileset: Tileset): TilesetReader
local TilesetReader = Class()

TilesetReader.FORMAT = "unknown"
TilesetReader.LEGACY_FORMAT = false

function TilesetReader:init(tileset)
    self.tileset = tileset
    self.operations = self.operations or {}
end

function TilesetReader:call(operation, ...)
    local callback = self.operations[operation]
    if not callback then
        error(string.format("%s does not implement tileset operation '%s'",
            ClassUtils.getClassName(self), tostring(operation)), 2)
    end
    return callback(self.tileset, ...)
end

function TilesetReader:initialize(data, path, base_dir)
    error(ClassUtils.getClassName(self) .. " does not implement tileset initialization", 2)
end

function TilesetReader:getFormat()
    return self.FORMAT
end

function TilesetReader:isLegacyFormat()
    return self.LEGACY_FORMAT == true
end

function TilesetReader:save(path, options)
    return false, string.format("Tileset format '%s' has no saving implementation!", tostring(self:getFormat()))
end

return TilesetReader
