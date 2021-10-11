local Sprite = newClass(Object)

function Sprite:init(texture, x, y, allow_anim)
    super:init(self, x, y)

    if type(texture) == "table" or (type(texture) == "string" and kristal.assets.getFrames(texture)) then
        self:setAnimation(texture)
    else
        self:setTexture(texture)
    end

    self.speed = 1
    self.current_frame = 1
    self.anim_delay = 0.25
    self.anim_progress = 0
    self.playing = false
end

function Sprite:updateTexture()
    if self.frames then
        self:setTexture(self.frames[self.current_frame], true)
    end
end

function Sprite:setTexture(texture, keep_anim)
    if not keep_anim then
        self.frames = nil
        self.current_frame = 1
        self.playing = false
        self.anim_progress = 0
    end
    if type(texture) == "string" then
        self.texture = kristal.assets.getTexture(texture)
    else
        self.texture = texture
    end
    if self.texture then
        self.width = self.texture:getWidth()
        self.height = self.texture:getHeight()
    else
        self.width = 0
        self.height = 0
    end
end

function Sprite:getTexture()
    return self.texture
end

function Sprite:setProgress(progress)
    self:setFrame(math.floor(#self.frames * progress) + 1)
end

function Sprite:setFrame(frame)
    self.current_frame = ((frame - 1) % #self.frames) + 1
    self:updateTexture()
end

function Sprite:setAnimation(frames)
    local old_frames = self.frames
    if type(frames) == "string" then
        self.frames = kristal.assets.getFrames(frames)
    else
        self.frames = frames
    end
    if not utils.equal(old_frames, self.frames) then
        self.current_frame = 1
    end
    self:updateTexture()
end

function Sprite:play(speed, reset)
    self.anim_delay = speed or 0.25
    self.playing = true
    if reset then
        self.current_frame = 1
        self.anim_progress = 0
    end
    self:updateTexture()
end

function Sprite:resume()
    self.playing = true
end

function Sprite:stop()
    self.playing = false
    self.current_frame = 1
    self.anim_progress = 0
end

function Sprite:pause()
    self.playing = false
end

function Sprite:update(dt)
    if self.playing then
        self.anim_progress = self.anim_progress + dt
        self:setProgress(self.anim_progress / (#self.frames * self.anim_delay))
    end

    super:update(self, dt)
end

function Sprite:draw()
    if self.texture then
        love.graphics.draw(self.texture)
    end

    super:draw(self)
end

return Sprite