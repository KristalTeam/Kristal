---@class GonerBackground : Object
---@overload fun(...) : GonerBackground
local GonerBackground, super = Class(Object)

function GonerBackground:init(x, y)
    super.init(self, x or SCREEN_WIDTH/2, y or SCREEN_HEIGHT/2, 320, 240)
    self:setScale(2)
    self:setOrigin(0, 0)

    self.sprite = Assets.getTexture("IMAGE_DEPTH")

    self.parallax_x = 0
    self.parallax_y = 0

    self.OBM = 0.5

    self.ob_depth = 0

    self.timer = Timer()
    self.timer:every(40/30, function()
        self.ob_depth = self.ob_depth - 0.001
        local piece = self:addChild(GonerBackgroundPiece(self.sprite, self.x, self.y))
        piece.stretch_speed = 0.01 * self.OBM
        piece.layer = self.ob_depth
    end)
    self:addChild(self.timer)

    self.music = Music()
    self.music:play("AUDIO_ANOTHERHIM")
    self.music:setPitch(0.02)
    self.music_pitch = 0.02
end

function GonerBackground:update()
    if (self.music_pitch < 0.96) then
        self.music_pitch = self.music_pitch + 0.02 * DTMULT
    end
    self.music:setPitch(self.music_pitch)

    super.update(self)
end

return GonerBackground