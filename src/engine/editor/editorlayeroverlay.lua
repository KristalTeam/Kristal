---@class EditorLayerOverlay : Class
---@overload fun(layer: table, layer_type?: table, depth?: number): EditorLayerOverlay
local EditorLayerOverlay = Class()

function EditorLayerOverlay:init(layer, layer_type, depth)
    self.source_layer = layer
    self.layer_uid = layer._editor_uid
    self.layer = depth or 0
    self.layer_type = layer_type
    self.color = Registry.layer_types:getLayerColor(layer, layer_type)
    self.visible = true
end

local function pointCoordinates(point)
    return point.x or point[1] or 0, point.y or point[2] or 0
end

local function collectPoints(points)
    local result = {}
    for _, point in ipairs(points or {}) do
        local x, y = pointCoordinates(point)
        table.insert(result, x)
        table.insert(result, y)
    end
    return result
end

function EditorLayerOverlay:drawObject(object, alpha)
    local width, height = object.width or 0, object.height or 0
    local points = object.polygon or object.polyline
    love.graphics.push()
    love.graphics.translate((object.x or 0) + (self.source_layer.offsetx or 0),
        (object.y or 0) + (self.source_layer.offsety or 0))
    love.graphics.rotate(math.rad(object.rotation or 0))
    local previous_width = love.graphics.getLineWidth()
    if object.polyline and object.shape_data and tonumber(object.shape_data.thickness) then
        love.graphics.setLineWidth(math.max(1, tonumber(object.shape_data.thickness)))
    end

    local color = self.color
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1, 0.14 * alpha)
    if points then
        if #points >= 3 and object.polygon then
            love.graphics.polygon("fill", collectPoints(points))
        end
    elseif object.shape == "ellipse" and width > 0 and height > 0 then
        love.graphics.ellipse("fill", width / 2, height / 2, width / 2, height / 2)
    elseif width > 0 or height > 0 then
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.9) * alpha)
    if points then
        local coordinates = collectPoints(points)
        if object.polygon and #coordinates >= 6 then
            love.graphics.polygon("line", coordinates)
        elseif #coordinates >= 4 then
            for _, edge in ipairs(MapUtils.getPolylineEdges(object, #points)) do
                local first, second = points[edge[1]], points[edge[2]]
                local x1, y1 = pointCoordinates(first)
                local x2, y2 = pointCoordinates(second)
                love.graphics.line(x1, y1, x2, y2)
            end
        end
    elseif object.shape == "ellipse" and width > 0 and height > 0 then
        love.graphics.ellipse("line", width / 2, height / 2, width / 2, height / 2)
    elseif width > 0 or height > 0 then
        love.graphics.rectangle("line", 0, 0, width, height)
    else
        love.graphics.line(-4, 0, 4, 0)
        love.graphics.line(0, -4, 0, 4)
    end
    love.graphics.setLineWidth(previous_width)
    love.graphics.pop()
end

function EditorLayerOverlay:draw(alpha)
    if not self.visible then return end
    alpha = alpha or 1
    local previous_width = love.graphics.getLineWidth()
    love.graphics.setLineWidth(1)
    for _, object in ipairs(self.source_layer.objects or {}) do
        if object.visible ~= false then self:drawObject(object, alpha) end
    end
    love.graphics.setLineWidth(previous_width)
    Draw.setColor(1, 1, 1, 1)
end

return EditorLayerOverlay
