---@class GonerBackground : Object
---@overload fun(...) : GonerBackground
local GonerBackground, super = Class(Object)

function GonerBackground:init(x, y)
    super.init(self, x or SCREEN_WIDTH / 2, y or SCREEN_HEIGHT / 2, 320, 240)
    self:setOrigin(0.5)
    self:setParallax(0, 0)
    self:setScale(2)

    self.sprite = Assets.getTexture("IMAGE_DEPTH")

    self.OBM = 0.5

    self.ob_depth = 0

    self.timer = Timer()
    self.timer:every(40/30, function()
        self.ob_depth = self.ob_depth - 0.001
        local piece = self:addChild(GonerBackgroundPiece(self.sprite, self.width / 2, self.height / 2))
        piece.stretch_speed = 0.01 * self.OBM
        piece.layer = self.ob_depth
    end)
    self:addChild(self.timer)

    self.cover = self:addChild(Rectangle(self.width / 2, self.height / 2, self.width, self.height))
    self.cover:setOrigin(0.5)
    self.cover:setLayer(9999999)
    self.cover:setColor({ 0, 0, 0, 0.4 })

    self.music = Music()
    self.music:play("AUDIO_ANOTHERHIM")
    self.music:setPitch(0.02)
    self.music_pitch = 0.02
end

function GonerBackground:update()
    self.music_pitch = Utils.approach(self.music_pitch, 0.96, 0.02 * DTMULT)
    self.music:setPitch(self.music_pitch)

    super.update(self)
end

return GonerBackground
