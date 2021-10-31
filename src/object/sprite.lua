local Sprite, super = Class(Object)

function Sprite:init(texture, x, y, width, height, path)
    super:init(self, x, y, width, height)

    self.use_texture_size = (width == nil)
    self.path = path or ""

    self:setSprite(texture)

    self.frame = 1
    self.loop = false
    self.playing = false
    self.anim_speed = 1

    self.anim_routine = nil

    self.anim_sprite = ""
    self.anim_delay = 0
    self.anim_frames = nil
    self.anim_duration = -1
    self.anim_callback = nil
    self.anim_waiting = 0
    self.anim_wait_func = function(s) self.anim_waiting = s; coroutine.yield() end
end

function Sprite:updateTexture()
    if self.frames then
        self:setTextureExact(self.frames[self.frame], true)
    end
end

function Sprite:getTexture()
    return self.texture
end

function Sprite:setProgress(progress)
    self:setFrame(math.floor(#self.frames * progress) + 1)
end

function Sprite:getPath(name)
    if self.path ~= "" and name ~= "" then
        return self.path.."/"..name
    else
        return self.path..name
    end
end

function Sprite:setSprite(texture, keep_anim)
    if type(texture) == "string" then
        texture = self:getPath(texture)
    end
    if type(texture) == "table" or (type(texture) == "string" and Assets.getFrames(texture)) then
        self:setFrames(texture, keep_anim)
    else
        self:setTexture(texture, keep_anim)
    end
end

function Sprite:setTexture(texture, keep_anim)
    self.frames = nil
    self:setTextureExact(texture)
    if not keep_anim then
        self:stop()
    end
end

function Sprite:setTextureExact(texture)
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

function Sprite:setFrame(frame)
    self.frame = ((frame - 1) % (self.frames and #self.frames or 1)) + 1
    self:updateTexture()
end

function Sprite:setFrames(frames, keep_anim)
    if type(frames) == "string" then
        self.frames = Assets.getFrames(frames)
    else
        self.frames = frames
    end
    if not keep_anim then
        self:stop()
    end
    self:updateTexture()
end

function Sprite:setAnimation(anim)
    self:stop(true)
    self.anim_duration = -1

    local func
    if type(anim) == "table" then
        local has_routine = false
        if type(anim[1]) == "string" then
            self.anim_sprite = anim[1]
            self:setSprite(self.anim_sprite, true)
            if type(anim[2]) == "function" then
                func = anim[2]
                has_routine = true
            end
        elseif type(anim[1]) == "function" then
            func = anim[1]
            has_routine = true
        end

        self.anim_duration = anim.duration or -1
        self.anim_callback = anim.callback
        self.anim_waiting = 0

        if not has_routine then
            self.anim_delay = anim[2] or (1/30)
            self.loop = anim[3] or false
            self.anim_frames = anim.frames

            func = self._basicAnimation
        end
    elseif type(anim) == "function" then
        func = anim
    end
    self.anim_routine = coroutine.create(func)
    self.playing = true

    coroutine.resume(self.anim_routine, self, self.anim_wait_func)
end

function Sprite:_basicAnimation(wait)
    while true do
        if type(self.anim_frames) == "table" then
            for i = 1, #self.anim_frames do
                self:setFrame(self.anim_frames[i])
                wait(self.anim_delay)
            end
        else
            for i = 1, #self.frames do
                self:setFrame(i)
                wait(self.anim_delay)
            end
        end
        if not self.loop then
            break
        end
    end
end

function Sprite:play(speed, loop, on_finished)
    if loop == nil then
        loop = true
    end
    self:setAnimation({nil, speed, loop, callback = on_finished})
end

function Sprite:resume()
    self.playing = true
end

function Sprite:stop(keep_frame)
    self.playing = false
    self.loop = false

    self.anim_waiting = 0
    self.anim_routine = nil
    self.anim_frames = nil

    if not keep_frame then
        self.anim_duration = -1
        self:setFrame(1)
    end
end

function Sprite:pause()
    self.playing = false
end

function Sprite:update(dt)
    if not self.anim_routine or coroutine.status(self.anim_routine) == "dead" then
        self:stop(true)
    end
    if self.playing then
        if self.anim_waiting > 0 then
            self.anim_waiting = Utils.approach(self.anim_waiting, 0, dt * self.anim_speed)
        end
        if self.anim_waiting == 0 and coroutine.status(self.anim_routine) == "suspended" then
            coroutine.resume(self.anim_routine, self, self.anim_wait_func)
        end
        if coroutine.status(self.anim_routine) == "dead" then
            self:stop(true)

            if self.anim_callback and self.anim_duration == -1 then
                self.anim_callback(self)
            end
        end
    end
    if self.anim_callback then
        if self.anim_duration > 0 then
            self.anim_duration = Utils.approach(self.anim_duration, 0, dt)
        elseif self.anim_duration == 0 then
            self:stop(true)

            if self.anim_callback then
                self.anim_callback(self)
            end
        end
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