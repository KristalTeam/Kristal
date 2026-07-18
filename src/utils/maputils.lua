---@class MapUtils
local MapUtils = {}

---@param point table?
---@return number x
---@return number y
function MapUtils.getPointCoordinates(point)
    point = point or {}
    return point.x or point[1] or 0, point.y or point[2] or 0
end

---@param points table?
---@return number[] coordinates
function MapUtils.collectPointCoordinates(points)
    local result = {}
    for _, point in ipairs(points or {}) do
        local x, y = MapUtils.getPointCoordinates(point)
        table.insert(result, x)
        table.insert(result, y)
    end
    return result
end

---@param x number
---@param y number
---@param points table
---@return boolean inside
function MapUtils.pointInPolygon(x, y, points)
    if #points == 0 then return false end
    local inside, previous = false, points[#points]
    for _, point in ipairs(points) do
        local px, py = MapUtils.getPointCoordinates(point)
        local qx, qy = MapUtils.getPointCoordinates(previous)
        if (py > y) ~= (qy > y)
            and x < (qx - px) * (y - py) / (qy - py) + px then
            inside = not inside
        end
        previous = point
    end
    return inside
end

--- Walks a nested layer tree.
function MapUtils.walkLayers(layers, callback, depth, parent)
    depth = depth or 0
    for index, layer in ipairs(layers or {}) do
        local descend = callback(layer, depth, parent, layers, index)
        if descend ~= false and layer.layers then
            MapUtils.walkLayers(layer.layers, callback, depth + 1, layer)
        end
    end
end

function MapUtils.walkObjects(layers, callback)
    MapUtils.walkLayers(layers, function(layer, depth, parent)
        for index, object in ipairs(layer.objects or {}) do
            callback(object, layer, index, depth, parent)
        end
    end)
end

---@param object table
---@param legacy boolean?
---@return string?
function MapUtils.getObjectType(object, legacy)
    if type(object.type) == "string" and object.type ~= "" then return object.type:lower() end
    if legacy then
        if type(object.class) == "string" and object.class ~= "" then return object.class:lower() end
        if type(object.name) == "string" and object.name ~= "" then return object.name:lower() end
    end
end

---@param type_id string?
---@param allowed_types string[]?
---@return boolean
function MapUtils.isObjectTypeAllowed(type_id, allowed_types)
    if type(allowed_types) ~= "table" or #allowed_types == 0 then return true end
    type_id = type(type_id) == "string" and type_id:lower() or type_id
    for _, allowed in ipairs(allowed_types) do
        if type(allowed) == "string" then allowed = allowed:lower() end
        if type_id == allowed then return true end
    end
    return false
end

function MapUtils.resolveMarkerReference(map_id, value)
    local reference = EditorObjectReference.from(value, map_id)
    map_id = reference.map_id or map_id
    if reference.object_id == nil or type(reference.object_id) == "number" then return reference end
    local data = Registry.getMapData(map_id)
    if not data then return reference end
    local marker_id = reference.object_id
    local reader = Registry.getMapReader(map_id)
    MapUtils.walkObjects(data.layers, function(object, layer)
        local object_type = MapUtils.getObjectType(object, true)
        if Registry.layer_types and reader and reader.LEGACY_FORMAT then
            object_type = Registry.layer_types:getLegacyTiledObjectType(layer, object) or object_type
        end
        if object_type == "marker" or object_type == "player" then
            if tostring(object.id) == tostring(reference.object_id)
                or tostring(object.name) == tostring(reference.object_id) then
                marker_id = object.id
            end
        end
    end)
    return EditorObjectReference(map_id, marker_id)
end

--- Unpacks the global tile id and transform flags used by runtime TileLayers.
function MapUtils.unpackTileGid(id)
    return bit.band(id, 0x0FFFFFFF),
        bit.band(id, 0x80000000) ~= 0,
        bit.band(id, 0x40000000) ~= 0,
        bit.band(id, 0x20000000) ~= 0
end

--- Resolves marker data, object references, marker ids, or coordinate pairs.
---@param obj Object
---@param target MarkerRef
---@param name string
---@return number x
---@return number y
---@return Marker? data
function MapUtils.parseMarkerProperty(obj, target, name)
    if type(target) == "table" and (target.object_id ~= nil or target.object ~= nil) then
        local target_map = target.map_id or target.map
        if target_map and Game.world.map.id ~= target_map then
            error(string.format("%s at (%d, %d) has cross-map position property \"%s\" targeting %s",
                ClassUtils.getClassName(obj), obj.x, obj.y, name, tostring(target_map)))
        end
        target = target.object_id or target.object
    end
    if type(target) == "table" then
        if target.center_x ~= nil and target.center_y ~= nil then
            return target.center_x, target.center_y, target
        elseif target.id ~= nil then
            if not Game.world.map:hasMarker(target) then
                error(string.format("%s at (%d, %d) has invalid position property \"%s\"",
                    ClassUtils.getClassName(obj), obj.x, obj.y, name))
            end
            return Game.world.map:getMarker(target)
        elseif target[1] ~= nil and target[2] ~= nil then
            return target[1], target[2], nil
        end
        error(string.format("%s at (%d, %d) has invalid position property \"%s\"",
            ClassUtils.getClassName(obj), obj.x, obj.y, name))
    end
    if not Game.world.map:hasMarker(target) then
        error(string.format("%s at (%d, %d) has invalid position property \"%s\"",
            ClassUtils.getClassName(obj), obj.x, obj.y, name))
    end
    return Game.world.map:getMarker(target)
end

--- Reads a list property.
function MapUtils.parsePropertyList(id, properties)
    properties = properties or {}
    if properties[id] ~= nil then
        if type(properties[id]) == "table" and TableUtils.isArray(properties[id]) then
            return properties[id]
        end
        return { properties[id] }
    end
    local result, index = {}, 1
    while properties[id .. index] ~= nil do
        table.insert(result, properties[id .. index])
        index = index + 1
    end
    return result
end

--- Reads a nested list property.
function MapUtils.parsePropertyMultiList(id, properties)
    properties = properties or {}
    if type(properties[id]) == "table" and TableUtils.isArray(properties[id]) then
        for _, value in ipairs(properties[id]) do
            if not (type(value) == "table" and TableUtils.isArray(value)) then
                return { properties[id] }
            end
        end
        return properties[id]
    end
    local single = MapUtils.parsePropertyList(id, properties)
    if #single > 0 then return { single } end
    local result, outer = {}, 1
    while properties[id .. outer .. "_1"] ~= nil do
        local list, inner = {}, 1
        while properties[id .. outer .. "_" .. inner] ~= nil do
            table.insert(list, properties[id .. outer .. "_" .. inner])
            inner = inner + 1
        end
        table.insert(result, list)
        outer = outer + 1
    end
    return result
end

function MapUtils.parseFlagProperties(flag, inverted, value, default_value, properties)
    properties = properties or {}
    local result_inverted = false
    local result_flag
    local result_value = default_value
    if properties[flag] then
        result_inverted, result_flag = StringUtils.startsWith(properties[flag], "!")
    end
    if properties[inverted] then result_inverted = not result_inverted end
    if properties[value] ~= nil then result_value = properties[value] end
    return result_flag, result_inverted, result_value
end

function MapUtils.getPolylineEdges(data, point_count)
    local shape_data = data and data.shape_data or data or {}
    local source = shape_data.edges
    local result = {}
    for _, edge in ipairs(type(source) == "table" and source or {}) do
        local first = tonumber(edge.from or edge[1])
        local second = tonumber(edge.to or edge[2])
        if first and second and first >= 1 and second >= 1
            and first <= point_count and second <= point_count and first ~= second then
            table.insert(result, { first, second })
        end
    end
    if source == nil then
        for index = 1, math.max(0, point_count - 1) do
            table.insert(result, { index, index + 1 })
        end
    end
    return result
end

--- Creates a collider from the runtime shape representation shared by map readers.
---@param parent Object
---@param data table
---@param x? number
---@param y? number
---@param properties? table
---@return Collider? collider
function MapUtils.colliderFromShape(parent, data, x, y, properties)
    x, y = x or 0, y or 0
    properties = properties or {}
    local mode = {
        invert = properties.inverted or properties.outside or false,
        inside = properties.inside or properties.outside or false
    }
    local rotation = math.rad((tonumber(data.rotation) or 0) % 360)
    local cosine, sine = math.cos(rotation), math.sin(rotation)
    local width, height = data.width or 0, data.height or 0
    local function transformPoint(point_x, point_y)
        return x + point_x * cosine - point_y * sine,
            y + point_x * sine + point_y * cosine
    end
    local function polygonCollider(points)
        local transformed = {}
        for _, point in ipairs(points) do
            local point_x, point_y = transformPoint(point.x or point[1] or 0, point.y or point[2] or 0)
            table.insert(transformed, { point_x, point_y })
        end
        return PolygonCollider(parent, transformed, mode)
    end

    local collider
    if data.shape == "rectangle" then
        if rotation == 0 then
            collider = Hitbox(parent, x, y, width, height, mode)
        else
            collider = polygonCollider({
                { x = 0, y = 0 }, { x = width, y = 0 },
                { x = width, y = height }, { x = 0, y = height }
            })
        end
    elseif data.shape == "polyline" or data.shape == "line" then
        local line_colliders = {}
        local points = data.polyline or data.shape_data and data.shape_data.points or {}
        for _, edge in ipairs(MapUtils.getPolylineEdges(data, #points)) do
            local first, second = points[edge[1]], points[edge[2]]
            local x1, y1 = transformPoint(first.x or first[1] or 0, first.y or first[2] or 0)
            local x2, y2 = transformPoint(second.x or second[1] or 0, second.y or second[2] or 0)
            table.insert(line_colliders, LineCollider(parent, x1, y1, x2, y2, mode))
        end
        collider = ColliderGroup(parent, line_colliders)
    elseif data.shape == "polygon" then
        collider = polygonCollider(data.polygon or data.shape_data and data.shape_data.points or {})
    elseif data.shape == "ellipse" then
        local points = {}
        local radius_x, radius_y = width / 2, height / 2
        for index = 0, 23 do
            local angle = index / 24 * math.pi * 2
            table.insert(points, {
                x = radius_x + math.cos(angle) * radius_x,
                y = radius_y + math.sin(angle) * radius_y
            })
        end
        collider = polygonCollider(points)
    elseif data.shape == "point" or data.point == true then
        collider = PointCollider(parent, x, y, mode)
    end
    if collider and properties.enabled == false then collider.collidable = false end
    return collider
end

return MapUtils
