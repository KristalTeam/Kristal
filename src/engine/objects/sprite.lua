local Sprite, super = Class(Object)

function Sprite:init(texture, x, y, width, height, path)
    super:init(self, x, y, width, height)

    self.use_texture_size = (width == nil)
    self.path = path or ""

    self:setSprite(texture)

    self.wrap_texture_x = false
    self.wrap_texture_y = false

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

function Sprite:set(texture)
    if type(texture) == "table" then
        self:setAnimation(texture)
    else
        self:setSprite(texture)
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
    self.texture_path = Assets.getTextureID(texture)
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
        if type(anim[1]) == "string" or type(anim[1]) == "table" then
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

        if anim.next then
            local next = anim.next
            if type(anim.next) == "table" then
                next = Utils.pick(anim.next)
            end
            local old_callback = self.anim_callback
            self.anim_callback = function(s)
                self:set(next)
                if old_callback then
                    old_callback(s)
                end
            end
        end

        if not has_routine then
            self.anim_delay = anim[2] or (1/30)
            self.loop = anim[3] or false
            self.anim_frames = self:parseFrames(anim.frames)

            func = self._basicAnimation
        end
    elseif type(anim) == "function" then
        func = anim
    end
    self.anim_routine = coroutine.create(func)
    self.playing = true

    coroutine.resume(self.anim_routine, self, self.anim_wait_func)
end

function Sprite:parseFrames(frames)
    if not frames then return end
    local t = {}
    for k,v in ipairs(frames) do
        if type(v) == "number" then
            table.insert(t, v)
        elseif type(v) == "string" then
            local arg_i = string.find(v, "-")
            if arg_i then
                local num1, num2 = tonumber(string.sub(v,1,arg_i-1)), tonumber(string.sub(v,arg_i+1,-1))
                for i=num1, num2, (num1 < num2) and 1 or -1 do
                    table.insert(t, i)
                end
            else
                arg_i = string.find(v, "*")
                if arg_i then
                    local num1, num2 = tonumber(string.sub(v,1,arg_i-1)), tonumber(string.sub(v,arg_i+1,-1))
                    for i=1,num2 do
                        table.insert(t, num1)
                    end
                else
                    error("Could not parse string at frame index "..k)
                end
            end
        else
            error("Frame index "..k.." must be either a number or string")
        end
    end
    return t
end

function Sprite:_basicAnimation(wait)
    while true do
        if type(self.anim_frames) == "table" then
            for i = 1, #self.anim_frames do
                self:setFrame(self.anim_frames[i])
                wait(self.anim_delay)
            end
            if not self.loop then break end
        else
            self:setFrame(1)
            wait(self.anim_delay)
            while self.frame < #self.frames do
                self:setFrame(self.frame + 1)
                wait(self.anim_delay)
            end
            if not self.loop then break end
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

function Sprite:update()
    if not self.anim_routine or coroutine.status(self.anim_routine) == "dead" then
        self:stop(true)
    end
    if self.playing then
        if self.anim_waiting > 0 then
            self.anim_waiting = Utils.approach(self.anim_waiting, 0, DT * self.anim_speed)
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
            self.anim_duration = Utils.approach(self.anim_duration, 0, DT)
        elseif self.anim_duration == 0 then
            self:stop(true)

            if self.anim_callback then
                self.anim_callback(self)
            end
        end
    end

    super:update(self)
end

function Sprite:draw()
    if self.texture then
        if self.wrap_texture_x or self.wrap_texture_y then
            local screen_l, screen_u = love.graphics.inverseTransformPoint(0, 0)
            local screen_r, screen_d = love.graphics.inverseTransformPoint(SCREEN_WIDTH, SCREEN_HEIGHT)

            local x1, y1 = math.min(screen_l, screen_r), math.min(screen_u, screen_d)
            local x2, y2 = math.max(screen_l, screen_r), math.max(screen_u, screen_d)

            local x_offset = math.floor(x1 / self.texture:getWidth()) * self.texture:getWidth()
            local y_offset = math.floor(y1 / self.texture:getHeight()) * self.texture:getHeight()

            local wrap_width = math.ceil((x2 - x_offset) / self.texture:getWidth())
            local wrap_height = math.ceil((y2 - y_offset) / self.texture:getHeight())

            if self.wrap_texture_x and self.wrap_texture_y then
                for i = 1, wrap_width do
                    for j = 1, wrap_height do
                        love.graphics.draw(self.texture, x_offset + (i-1) * self.texture:getWidth(), y_offset + (j-1) * self.texture:getHeight())
                    end
                end
            elseif self.wrap_texture_x then
                for i = 1, wrap_width do
                    love.graphics.draw(self.texture, x_offset + (i-1) * self.texture:getWidth(), 0)
                end
            elseif self.wrap_texture_y then
                for j = 1, wrap_height do
                    love.graphics.draw(self.texture, 0, y_offset + (j-1) * self.texture:getHeight())
                end
            end
        else
            love.graphics.draw(self.texture)
        end
    end

    super:draw(self)
end

return Sprite