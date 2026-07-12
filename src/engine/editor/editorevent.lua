---@class EditorEvent : Class
---@field placement_shape "rectangle"|"point"|"region"
---@overload fun(data?: table, options?: table): EditorEvent
local EditorEvent = Class()

-- Event classes may override this with "point" when their position has no
-- bounded area, or "region" when placement should be defined by dragging.
EditorEvent.placement_shape = "rectangle"

function EditorEvent:registerProperty(id, property_type, options)
    options = TableUtils.copy(options or {}, true)
    if property_type == "object_reference" and options.map_id == nil then options.map_id = self.map_id end
    return self.property_set:registerProperty(id, property_type, options)
end

function EditorEvent:registerPropertyGroup(id, options)
    return self.property_set:registerGroup(id, options)
end

function EditorEvent:init(data, options)
    data = data or {}
    options = options or {}
    self.map_id = options.map_id
    self.data = data
    data.properties = data.properties or {}
    data.__editor_property_types = data.__editor_property_types or {}
    self.properties = data.properties
    self.property_types = data.__editor_property_types
    self.property_set = EditorPropertySet(data.properties, data.__editor_property_types)
    self:registerProperty("uid", "string", { name = "Unique ID" })
    self:registerProperty("cond", "string", { name = "Load Condition" })
    self:registerProperty("flagcheck", "string", { name = "Load Flag" })
    self:registerProperty("flagvalue", "value", { name = "Load Flag Value" })
    self.id = options.event_id
    self.layer = options.depth or 0
    self.layer_uid = options.layer_uid
    self.layer_type = options.layer_type
    self.layer_color = options.layer_color or { 1, 1, 1, 1 }
    self.x = (data.x or 0) + (options.offset_x or 0)
    self.y = (data.y or 0) + (options.offset_y or 0)
    self.width = data.width or 0
    self.height = data.height or 0
    self.rotation = math.rad(data.rotation or 0)
    self.visible = data.visible ~= false
    self.sprite = self:getPreviewSprite(options.sprite)
end

function EditorEvent:getPreviewSprite(sprite)
    local properties = self.data.properties or {}
    local candidates = { sprite }
    if self.sprite_property then table.insert(candidates, properties[self.sprite_property]) end
    if self.getEditorSprite then
        local success, result = pcall(self.getEditorSprite, self, self.data)
        if success then table.insert(candidates, result) end
    end
    table.insert(candidates, self.editor_sprite)
    for _, candidate in ipairs(candidates) do
        if type(candidate) == "string" then
            if Assets.getFramesOrTexture(candidate) then return candidate end
            for _, direction in ipairs({ "down", "right", "left", "up" }) do
                local directional = candidate .. "/" .. direction
                if Assets.getFramesOrTexture(directional) then return directional end
            end
        end
    end
    return nil
end

function EditorEvent:getTexture()
    local frames = self.sprite and Assets.getFramesOrTexture(self.sprite)
    if frames and frames[1] then return frames[1], false end
    if self.width == 0 and self.height == 0 then
        return Assets.getTexture("editor/marker"), true
    end
    return nil, false
end

function EditorEvent:draw(alpha)
    if not self.visible then return end
    alpha = alpha or 1
    local texture, marker = self:getTexture()
    if not texture then return end
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    if marker then
        local color = self.layer_color
        Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1, (color[4] or 1) * alpha)
    else
        Draw.setColor(1, 1, 1, alpha)
    end
    if marker then
        Draw.draw(texture, 0, 0, 0, 2, 2, texture:getWidth() / 2, texture:getHeight())
    elseif self.width ~= 0 or self.height ~= 0 then
        Draw.draw(texture, self.width / 2, self.height / 2, 0, 2, 2,
            texture:getWidth() / 2, texture:getHeight() / 2)
    else
        Draw.draw(texture, 0, 0, 0, 2, 2)
    end
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
end

function EditorEvent:drawPreviewIcon(x, y, width, height, alpha)
    local texture, marker = self:getTexture()
    if not texture then return false end
    alpha = alpha or 1
    local texture_width, texture_height = texture:getDimensions()
    local scale = math.min(width / texture_width, height / texture_height)
    local color = marker and self.layer_color or { 1, 1, 1, 1 }
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1, (color[4] or 1) * alpha)
    Draw.draw(texture, x + width / 2, y + height / 2, 0, scale, scale,
        texture_width / 2, texture_height / 2)
    Draw.setColor(1, 1, 1, 1)
    return true
end

function EditorEvent:drawBounds(alpha)
    if self.width == 0 and self.height == 0
        and not self.data.polygon and not self.data.polyline then return end
    alpha = alpha or 1
    local previous_width = love.graphics.getLineWidth()
    local color = self.layer_color
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    local thickness = self.data.shape_data and tonumber(self.data.shape_data.thickness)
    love.graphics.setLineWidth(math.max(1, thickness or 1))
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.9) * alpha)
    if self.data.shape == "ellipse" then
        love.graphics.ellipse("line", self.width / 2, self.height / 2, self.width / 2, self.height / 2)
    elseif self.data.polygon and #self.data.polygon >= 3 then
        local points = {}
        for _, point in ipairs(self.data.polygon) do
            table.insert(points, point.x or point[1] or 0)
            table.insert(points, point.y or point[2] or 0)
        end
        love.graphics.polygon("line", points)
    elseif self.data.polyline and #self.data.polyline >= 2 then
        for _, edge in ipairs(MapUtils.getPolylineEdges(self.data, #self.data.polyline)) do
            local first, second = self.data.polyline[edge[1]], self.data.polyline[edge[2]]
            love.graphics.line(first.x or first[1] or 0, first.y or first[2] or 0,
                second.x or second[1] or 0, second.y or second[2] or 0)
        end
    else
        love.graphics.rectangle("line", 0, 0, self.width, self.height)
    end
    love.graphics.pop()
    love.graphics.setLineWidth(previous_width)
    Draw.setColor(1, 1, 1, 1)
end

return EditorEvent
