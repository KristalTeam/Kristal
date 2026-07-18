---@class TiledUtils
local TiledUtils = {}

---
--- Converts a "marker input" to a set of coordinates.
---
--- This can either take a tiled object reference, a string, marker data itself (which'll get returned untouched) or a user-made position table.
---
--- NOTE: Don't put this in your event's `init`! Markers aren't guaranteed to be loaded at that point. Use `onLoad` instead.
---
--- This will error if no marker exists.
---
---@param obj Object # The object calling this function. Most of the time, you should just enter `self`.
---@param target MarkerRef The marker input.
---@param name string # The name of the property being parsed, used for error messages.
---@return number x
---@return number x
---@return Marker? data
---@deprecated Use `MapUtils.parseMarkerProperty` instead.
function TiledUtils.parseMarkerProperty(obj, target, name)
    return MapUtils.parseMarkerProperty(obj, target, name)
end

---
--- Converts a Tiled color property to an RGBA color table.
---
---@param property string # The property string to convert.
---@return number[]? rgba # The converted RGBA table.
---
function TiledUtils.parseColorProperty(property)
    if not property then return nil end
    -- Tiled color properties are formatted as #AARRGGBB, where AA is the alpha value.
    -- Unfortunately, hexToRGB's alpha support is only #RRGGBBAA, so we need to do this ourselves.

    local str = "#" .. string.sub(property, 4) -- Get the hex string without the alpha value
    local alpha = tonumber(string.sub(property, 2, 3), 16) / 255 -- Get the alpha value separately
    local r, g, b, a = ColorUtils.unpackColor(ColorUtils.hexToRGB(str))
    return { r, g, b, a * (alpha or 1) }
end

---
--- Returns a table with values based on Tiled properties.
---
--- The function will check for a series of numbered properties starting with the specified `id` string, eg. `"id1"`, followed by `"id2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
---@deprecated Use `MapUtils.parsePropertyList` instead.
function TiledUtils.parsePropertyList(id, properties)
    return MapUtils.parsePropertyList(id, properties)
end

---
--- Returns an array of tables with values based on Tiled properties. \
--- The function will check for a series of layered numbered properties started with the specified `id` string, eg. `"id1_1"`, followed by `"id1_2"`, `"id2_1"`, `"id2_2"`, etc. \
--- \
--- The returned table will contain a list of tables correlating to each individual list. \
--- For example, the first table in the returned array will contain the values for `"id1_1"` and `"id1_2"`, the second table will contain `"id2_1"` and `"id2_2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
---@deprecated Use `MapUtils.parsePropertyMultiList` instead.
function TiledUtils.parsePropertyMultiList(id, properties)
    return MapUtils.parsePropertyMultiList(id, properties)
end

---
--- Returns a series of values used to determine the behavior of a flag property for a Tiled event.
---
---@param flag string?     # The name of the flag property.
---@param inverted string? # The name of the property used to determine if the flag should be inverted.
---@param value string?    # The name of the property used to determine what the flag's value should be compared to.
---@param default_value any   # If a property for the `value` name is not found, the value will be this instead.
---@param properties table    # The properties table of a Tiled event's data.
---@return string flag        # The name of the flag to check.
---@return boolean inverted   # Whether the result of the check should be inverted.
---@return any value          # The value that the flag should be compared to.
---
---@deprecated Use `MapUtils.parseFlagProperties` instead.
function TiledUtils.parseFlagProperties(flag, inverted, value, default_value, properties)
    return MapUtils.parseFlagProperties(flag, inverted, value, default_value, properties)
end

---
--- Returns the actual GID and flip flags of a tile.
---
---@param id number          # The GID of the tile.
---@return integer gid       # The GID of the tile without the flags.
---@return boolean flip_x    # Whether the tile should be flipped horizontally.
---@return boolean flip_y    # Whether the tile should be flipped vertically.
---@return boolean flip_diag # Whether the tile should be flipped diagonally.
---
---@deprecated Use `MapUtils.unpackTileGid` instead.
function TiledUtils.parseTileGid(id)
    return MapUtils.unpackTileGid(id)
end

---
--- Creates a Collider based on a Tiled object shape.
---
---@param parent Object      # The object that the new Collider should be parented to.
---@param data table         # The Tiled shape data.
---@param x? number          # An optional value defining the horizontal position of the collider.
---@param y? number          # An optional value defining the vertical position of the collider.
---@param properties? table  # A table defining additional properties for the collider.
---@return Collider collider # The new Collider instance.
---
---@deprecated Use `MapUtils.colliderFromShape` instead.
function TiledUtils.colliderFromShape(parent, data, x, y, properties)
    return MapUtils.colliderFromShape(parent, data, x, y, properties)
end
--- Resolves explicit polyline point-index connections, falling back to a
--- conventional consecutive path when no topology is stored.
---@deprecated Use `MapUtils.getPolylineEdges` instead.
function TiledUtils.getPolylineEdges(data, point_count)
    return MapUtils.getPolylineEdges(data, point_count)
end
---@alias TiledUtils.PathFailReason
---| "not under prefix"
---| "path outside root"

---
--- Attempts to resolve a relative path from a Tiled export to a valid asset id, given it points to a path inside the
--- `target_dir` of the current project.
---
--- Relative directories (`..`) of the asset path are resolved by starting from the `source_dir`, which should match the
--- directory the Tiled data was exported to. Exporting to a different directory and copying/moving the exported data will
--- likely cause this relative search to fail.
---
---@param target_dir string # The Kristal folder to get the path relative to.
---@param asset_path string # The asset path from a Tiled export to resolve.
---@param source_dir string # Parent directory of the Tiled export, which the `asset_path` should be relative to.
---@return boolean success # Whether the path resolution was successful.
---@return string|TiledUtils.PathFailReason result # If resolution was successful, this is the asset path relative the `target_dir` without its extension. Otherwise, this is a reason the resolution failed.
---@return string final_path # The final path with its extension, possibly unresolved if resolution failed. Used for debugging.
---
function TiledUtils.relativePathToAssetId(target_dir, asset_path, source_dir)
    local prefix = Mod.info.path .. "/" .. target_dir .. "/"

    -- Split paths by seperator
    local base_parts = StringUtils.split(source_dir, "/")
    -- Separator is assumed to be a forward slash as Tiled uses it
    local dest_parts = StringUtils.split(asset_path, "/")

    local up_count = 0
    while dest_parts[1] == ".." do
        up_count = up_count + 1
        -- Move up one directory
        if #base_parts == 0 then
            return false, "path outside root", table.concat(dest_parts, "/")
        end
        table.remove(base_parts, #base_parts)
        table.remove(dest_parts, 1)
    end

    -- Strip library directory prefix
    if dest_parts[1] == "libraries" then
        for _ = 2, up_count do
            table.remove(dest_parts, 1)
        end
    end

    local final_path = table.concat(TableUtils.merge(base_parts, dest_parts), "/")

    -- Strip prefix
    local has_prefix
    has_prefix, final_path = StringUtils.startsWith(final_path, prefix)

    if not has_prefix then
        return false, "not under prefix", final_path
    end

    -- Strip extension
    return true, final_path:sub(1, -1 - (final_path:reverse():find("%.") or 0)), final_path
end

---@param asset_path string
---@param source_dir string
---@return boolean success
---@return string result
function TiledUtils.resolveImageAsset(asset_path, source_dir)
    local image_dir = "assets/sprites"
    local success, result, final_path = TiledUtils.relativePathToAssetId(image_dir, asset_path, source_dir)
    if success then return true, result end
    if result == "not under prefix" then
        return false, "Image not found in \"" .. image_dir .. "\" (Got path \"" .. final_path .. "\")"
    elseif result == "path outside root" then
        return false, "Image path located outside Kristal (Got path \"<kristal>/" .. final_path .. "\")"
    end
    return false, "Unknown reason"
end

return TiledUtils
