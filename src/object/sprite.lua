local Sprite, super = Class(Object)

function Sprite:init(texture, x, y, width, height)
    super:init(self, x, y, width, height)

    self.use_texture_size = (width == nil)

    self:setSprite(texture)

    self.speed = 1
    self.frame = 1
    self.anim_delay = 0.25
    self.anim_progress = 0
    self.anim_finished = false
    self.on_finished = nil
    self.loop = true
    self.playing = false
end

function Sprite:updateTexture()
    if self.frames then
        self:setTexture(self.frames[self.frame], true)
    end
end

function Sprite:setSprite(texture)
    if type(texture) == "table" or (type(texture) == "string" and Assets.getFrames(texture)) then
        self:setAnimation(texture)
    else
        self:setTexture(texture)
    end
end

function Sprite:setTexture(texture, keep_anim)
    if not keep_anim then
        self.frames = nil
        self.frame = 1
        self.playing = false
        self.anim_progress = 0
        self.on_finished = nil
    end
    if type(texture) == "string" then
        self.texture = Assets.getTexture(texture)
    else
        self.texture = texture
    end
    if self.use_texture_size then
        if self.texture then
            self.width = self.texture:getWidth()
            self.height = self.texture:getHeight()
        else
            self.width = 0
            self.height = 0
        end
    end
end

function Sprite:getTexture()
    return self.texture
end

function Sprite:setProgress(progress)
    self:setFrame(math.floor(#self.frames * progress) + 1)
end

function Sprite:setFrame(frame)
    if self.loop then
        self.frame = ((frame - 1) % (self.frames and #self.frames or 1)) + 1
        self.anim_finished = false
    else
        self.frame = math.min(frame, self.frames and #self.frames or 1)
        if frame > (self.frames and #self.frames or 1) then
            self.anim_finished = true
            if self.on_finished then
                self.on_finished()
                self.on_finished = nil
            end
        else
            self.anim_finished = false
        end
    end
    self:updateTexture()
end

function Sprite:setAnimation(frames, speed)
    local old_frames = self.frames
    if type(frames) == "string" then
        self.frames = Assets.getFrames(frames)
    else
        self.frames = frames
    end
    if not Utils.equal(old_frames, self.frames) then
        self.playing = false
        self.frame = 1
        self.anim_progress = 0
        self.on_finished = nil
    end
    if speed then
        self.playing = true
        self.anim_delay = speed
    end
    self:updateTexture()
end

function Sprite:play(speed, loop, reset, on_finished)
    if not self.frames then
        return
    end
    self.anim_delay = speed or 0.25
    self.playing = true
    if loop == nil then
        self.loop = true
    else
        self.loop = loop
    end
    if reset then
        self.current_frame = 1
        self.anim_progress = 0
        self.anim_finished = false
    end
    self.on_finished = on_finished
    self:updateTexture()
end

function Sprite:resume()
    self.playing = true
end

function Sprite:stop()
    self.playing = false
    self.loop = true
    self.on_finished = nil
    self:setProgress(0)
end

function Sprite:pause()
    self.playing = false
end

function Sprite:update(dt)
    if self.playing then
        self.anim_progress = self.anim_progress + dt
        self:setProgress(self.anim_progress / (#self.frames * self.anim_delay))
    end

    self:updateChildren(dt)
end

function Sprite:draw()
    if self.texture then
        love.graphics.draw(self.texture)
    end

    self:drawChildren()
end

return Sprite