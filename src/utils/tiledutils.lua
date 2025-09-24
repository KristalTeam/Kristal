---@class TiledUtils
local TiledUtils = {}

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
    local r, g, b, a = Utils.unpackColor(ColorUtils.hexToRGB(str))
    return { r, g, b, a * (alpha or 1) }
end

---
--- Returns a table with values based on Tiled properties. \
--- The function will check for a series of numbered properties starting with the specified `id` string, eg. `"id1"`, followed by `"id2"`, etc.
---
---@param id string        # The name the series of properties should all start with.
---@param properties table # The properties table of a Tiled event's data.
---@return table result    # The list of property values found.
---
function TiledUtils.parsePropertyList(id, properties)
    properties = properties or {}
    if properties[id] then
        -- Numberless property found, return it as the only value in the list
        return { properties[id] }
    else
        local result = {}
        -- Loop through properties with an increasing number suffix
        local i = 1
        while properties[id .. i] do
            table.insert(result, properties[id .. i])
            i = i + 1
        end
        return result
    end
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
function TiledUtils.parsePropertyMultiList(id, properties)
    local single_list = TiledUtils.parsePropertyList(id, properties)
    if #single_list > 0 then
        -- If a shallower list was found (e.g. "id1", "id2" instead of "id1_1", "id1_2"),
        -- return it as the only value in the list.
        return { single_list }
    else
        local result = {}
        local i = 1
        while properties[id .. i .. "_1"] do
            local list = {}
            local j = 1
            while properties[id .. i .. "_" .. j] do
                table.insert(list, properties[id .. i .. "_" .. j])
                j = j + 1
            end
            table.insert(result, list)
            i = i + 1
        end
        return result
    end
end

---
--- Returns a series of values used to determine the behavior of a flag property for a Tiled event.
---
---@param flag string|nil     # The name of the flag property.
---@param inverted string|nil # The name of the property used to determine if the flag should be inverted.
---@param value string|nil    # The name of the property used to determine what the flag's value should be compared to.
---@param default_value any   # If a property for the `value` name is not found, the value will be this instead.
---@param properties table    # The properties table of a Tiled event's data.
---@return string flag        # The name of the flag to check.
---@return boolean inverted   # Whether the result of the check should be inverted.
---@return any value          # The value that the flag should be compared to.
---
function TiledUtils.parseFlagProperties(flag, inverted, value, default_value, properties)
    properties = properties or {}

    local result_inverted = false
    local result_flag = nil
    local result_value = default_value

    if properties[flag] then
        -- If the flag property starts with an exclamation mark, the result should
        -- be inverted and the flag name should be the rest of the string.
        result_inverted, result_flag = StringUtils.startsWith(properties[flag], "!")
    end
    if properties[inverted] then
        result_inverted = not result_inverted
    end
    if properties[value] then
        result_value = properties[value]
    end

    return result_flag, result_inverted, result_value
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
function TiledUtils.parseTileGid(id)
    return bit.band(id, 0x0FFFFFFF),
        bit.band(id, 0x80000000) ~= 0,
        bit.band(id, 0x40000000) ~= 0,
        bit.band(id, 0x20000000) ~= 0
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
function TiledUtils.colliderFromShape(parent, data, x, y, properties)
    x, y = x or 0, y or 0
    properties = properties or {}

    -- Optional properties for collider behaviour
    -- "outside" is the same as enabling both "inverted" and "inside"
    local mode = {
        invert = properties["inverted"] or properties["outside"] or false,
        inside = properties["inside"] or properties["outside"] or false
    }

    local current_hitbox
    if data.shape == "rectangle" then
        -- For rectangles, create a Hitbox using the rectangle's dimensions
        current_hitbox = Hitbox(parent, x, y, data.width, data.height, mode)

    elseif data.shape == "polyline" then
        -- For polylines, create a ColliderGroup using a series of LineColliders
        local line_colliders = {}

        -- Loop through each pair of points in the polyline
        for i = 1, #data.polyline - 1 do
            local j = i + 1
            -- Create a LineCollider using the current and next point of the polyline
            local x1, y1 = x + data.polyline[i].x, y + data.polyline[i].y
            local x2, y2 = x + data.polyline[j].x, y + data.polyline[j].y
            table.insert(line_colliders, LineCollider(parent, x1, y1, x2, y2, mode))
        end

        current_hitbox = ColliderGroup(parent, line_colliders)

    elseif data.shape == "polygon" then
        -- For polygons, create a PolygonCollider using the polygon's points
        local points = {}

        for i = 1, #data.polygon do
            -- Convert points from the format {[x] = x, [y] = y} to {x, y}
            table.insert(points, { x + data.polygon[i].x, y + data.polygon[i].y })
        end

        current_hitbox = PolygonCollider(parent, points, mode)
    end

    if properties["enabled"] == false then
        current_hitbox.collidable = false
    end

    return current_hitbox
end

return TiledUtils
