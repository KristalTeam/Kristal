---@class EditorEvent : Class
---@field data table
---@field height number
---@field id string?
---@field layer number
---@field layer_color number[]
---@field layer_tint number[]
---@field layer_type table?
---@field layer_uid string?
---@field map_id string?
---@field properties table
---@field property_set EditorPropertySet
---@field property_types table
---@field rotation number
---@field scale_x number
---@field scale_y number
---@field sprite string?
---@field editor_sprite string?
---@field sprite_property string?
---@field visible boolean
---@field width number
---@field x number
---@field y number
---@field placement_shape "rectangle"|"point"|"region"
---@field scaling_mode "resize"|"scale"
---@overload fun(data?: table, options?: table): EditorEvent
local EditorEvent = Class()

-- Event classes may override this with "point" when their position has no
-- bounded area, or "region" when placement should be defined by dragging.
EditorEvent.placement_shape = "rectangle"

-- "resize" changes the object's actual bounds. "scale" preserves those bounds
-- and records a visual scale when the resize handles are dragged.
EditorEvent.scaling_mode = "resize"

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
    self.layer_tint = options.layer_tint or { 1, 1, 1, 1 }
    if math.max(self.layer_tint[1] or 0, self.layer_tint[2] or 0,
        self.layer_tint[3] or 0, self.layer_tint[4] or 0) > 1 then
        self.layer_tint = { (self.layer_tint[1] or 255) / 255,
            (self.layer_tint[2] or 255) / 255, (self.layer_tint[3] or 255) / 255,
            (self.layer_tint[4] or 255) / 255 }
    end
    self.x = (data.x or 0) + (options.offset_x or 0)
    self.y = (data.y or 0) + (options.offset_y or 0)
    self.width = data.width or 0
    self.height = data.height or 0
    self.scale_x = data.scale_x or 1
    self.scale_y = data.scale_y or 1
    self.rotation = math.rad(data.rotation or 0)
    self.visible = data.visible ~= false
    self.sprite = self:getPreviewSprite(options.sprite)
end

function EditorEvent:getShapeData()
    return { self.data.width, self.data.height, self.data.polygon }
end

function EditorEvent:getRectData()
    return { self.data.width, self.data.height }
end

function EditorEvent:getCharacterPosition(map)
    if self.data.gid or self.data.tileset and self.data.tile_id ~= nil then
        local x, y, width, height = map:getTileObjectRect(self.data)
        return x + width / 2, y + height
    end
    return self.data.center_x, self.data.center_y
end

---@param map Map
---@param context? {layer_type: string?, layer: table?, depth: number?, reader: MapReader?}
---@return Object?
function EditorEvent:createObject(map, context)
    error(ClassUtils.getClassName(self) .. ":createObject() must be overridden", 2)
end

function EditorEvent:getBoundsSize()
    if self.scaling_mode == "scale" then
        return self.width * math.abs(self.scale_x), self.height * math.abs(self.scale_y)
    end
    return self.width, self.height
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
        local tint = self.layer_tint
        Draw.setColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, alpha)
    end
    local width, height = self:getBoundsSize()
    if marker then
        Draw.draw(texture, 0, 0, 0, 2, 2, texture:getWidth() / 2, texture:getHeight())
    elseif self.width ~= 0 or self.height ~= 0 then
        local scale_x = self.scaling_mode == "scale" and self.scale_x or 1
        local scale_y = self.scaling_mode == "scale" and self.scale_y or 1
        Draw.draw(texture, width / 2, height / 2, 0, 2 * scale_x, 2 * scale_y,
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

function EditorEvent:drawBounds(alpha, line_width)
    if self.width == 0 and self.height == 0
        and not self.data.polygon and not self.data.polyline then return end
    alpha = alpha or 1
    local previous_width = love.graphics.getLineWidth()
    local color = self.layer_color
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    local thickness = self.data.shape_data and tonumber(self.data.shape_data.thickness)
    local width, height = self:getBoundsSize()
    love.graphics.setLineWidth(math.max(line_width or 1, (thickness or 1) * (line_width or 1)))
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.9) * alpha)
    if self.data.shape == "ellipse" then
        love.graphics.ellipse("line", width / 2, height / 2, width / 2, height / 2)
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
        love.graphics.rectangle("line", 0, 0, width, height)
    end
    love.graphics.pop()
    love.graphics.setLineWidth(previous_width)
    Draw.setColor(1, 1, 1, 1)
end

return EditorEvent
