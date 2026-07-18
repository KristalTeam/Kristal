--- Draws hitboxes and shapes for a layer in the editor/game preview.
---@class EditorLayerOverlay : Class
---@field color number[]
---@field layer number
---@field layer_type table?
---@field layer_uid string?
---@field source_layer table
---@field visible boolean
---@overload fun(layer: table, layer_type?: table, depth?: number): EditorLayerOverlay
local EditorLayerOverlay = Class()

function EditorLayerOverlay:init(layer, layer_type, depth)
    self.source_layer = layer
    self.layer_uid = layer._editor_uid
    MapUtils.addLayerOffset(self, depth)
    self.layer_type = layer_type
    self.color = Registry.layer_types:getLayerColor(layer, layer_type)
    self.visible = true
end

function EditorLayerOverlay:drawObject(object, alpha, line_width)
    local width, height = object.width or 0, object.height or 0
    local points = object.polygon or object.polyline
    love.graphics.push()
    love.graphics.translate((object.x or 0) + (self.source_layer.offsetx or 0),
        (object.y or 0) + (self.source_layer.offsety or 0))
    love.graphics.rotate(math.rad(object.rotation or 0))
    local previous_width = love.graphics.getLineWidth()
    if object.polyline and object.shape_data and tonumber(object.shape_data.thickness) then
        love.graphics.setLineWidth(math.max(line_width or 1,
            tonumber(object.shape_data.thickness) * (line_width or 1)))
    else
        love.graphics.setLineWidth(line_width or 1)
    end

    local color = self.color
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1, 0.14 * alpha)
    if points then
        if #points >= 3 and object.polygon then
            love.graphics.polygon("fill", MapUtils.collectPointCoordinates(points))
        end
    elseif object.shape == "ellipse" and width > 0 and height > 0 then
        love.graphics.ellipse("fill", width / 2, height / 2, width / 2, height / 2)
    elseif width > 0 or height > 0 then
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.9) * alpha)
    if points then
        local coordinates = MapUtils.collectPointCoordinates(points)
        if object.polygon and #coordinates >= 6 then
            love.graphics.polygon("line", coordinates)
        elseif #coordinates >= 4 then
            for _, edge in ipairs(MapUtils.getPolylineEdges(object, #points)) do
                local first, second = points[edge[1]], points[edge[2]]
                local x1, y1 = MapUtils.getPointCoordinates(first)
                local x2, y2 = MapUtils.getPointCoordinates(second)
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

function EditorLayerOverlay:draw(alpha, line_width, selected)
    if not self.visible then return end
    alpha = alpha or 1
    local previous_width = love.graphics.getLineWidth()
    love.graphics.setLineWidth(line_width or 1)
    for _, object in ipairs(self.source_layer.objects or {}) do
        if object.visible ~= false then self:drawObject(object, alpha, line_width) end
    end
    love.graphics.setLineWidth(previous_width)
    Draw.setColor(1, 1, 1, 1)
end

return EditorLayerOverlay
