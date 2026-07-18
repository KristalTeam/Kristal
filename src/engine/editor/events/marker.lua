---@class EditorMarker : EditorEvent
---@overload fun(data?: table, options?: table): EditorMarker
local EditorMarker, super = Class(EditorEvent)

EditorMarker.placement_shape = "point"
EditorMarker.runtime_type = "marker"

function EditorMarker:init(data, options)
    super.init(self, data, options)
    self:registerProperty("player_state", "string", { name = "Player State", default = "WALK" })
end

function EditorMarker:getTexture()
    return Assets.getTexture("editor/marker"), true
end

function EditorMarker:createObject()
    return nil
end

function EditorMarker:draw(alpha, line_width, selected)
    super.draw(self, alpha)
    local name = selected and StringUtils.trim(tostring(self.data.name or "")) or ""
    if name == "" then return end
    local texture = Assets.getTexture("editor/marker")
    local font = EditorFont.get(14)
    local scale = line_width or 1
    local text_width, text_height = font:getWidth(name), font:getHeight()
    local padding_x, padding_y = 5, 3
    local plate_width = text_width + padding_x * 2
    local plate_height = text_height + padding_y * 2
    local color = self.layer_color
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.translate(self.width / 2, self.height / 2)
    love.graphics.scale(scale, scale)
    local plate_x = -plate_width / 2
    local plate_y = -texture:getHeight() * 2 - plate_height - 5
    Draw.setColor(0.035, 0.035, 0.045, 0.9 * (alpha or 1))
    love.graphics.rectangle("fill", plate_x, plate_y, plate_width, plate_height)
    Draw.setColor(color[1] or 1, color[2] or 1, color[3] or 1,
        math.min(color[4] or 1, 0.95) * (alpha or 1))
    love.graphics.rectangle("line", plate_x + 0.5, plate_y + 0.5,
        plate_width - 1, plate_height - 1)
    love.graphics.setFont(font)
    Draw.setColor(1, 1, 1, alpha or 1)
    love.graphics.print(name, plate_x + padding_x, plate_y + padding_y)
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
end

return EditorMarker
