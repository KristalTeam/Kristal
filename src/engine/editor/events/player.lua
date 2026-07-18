---@class EditorPlayer : EditorEvent
---@overload fun(data?: table, options?: table): EditorPlayer
local EditorPlayer, super = Class(EditorEvent)

EditorPlayer.editor_name = "Player"
EditorPlayer.placement_shape = "point"
EditorPlayer.runtime_type = "player"

function EditorPlayer:init(data, options)
    super.init(self, data, options)
    self:registerProperty("player_state", "string", { name = "Player State", default = "WALK" })
end

function EditorPlayer:getTexture()
    return Assets.getTexture("editor/player"), false
end

function EditorPlayer:createObject()
    return nil
end

function EditorPlayer:draw(alpha)
    if not self.visible then return end
    local texture = Assets.getTexture("editor/player")
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    Draw.setColor(1, 1, 1, alpha or 1)
    Draw.draw(texture, 0, 0, 0, 2, 2, texture:getWidth() / 2, texture:getHeight())
    love.graphics.pop()
    Draw.setColor(1, 1, 1, 1)
end

return EditorPlayer
