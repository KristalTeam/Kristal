--- A simple object that renders a texture. \
--- This texture must be placed inside `assets/sprites/`.
---
---@class Sprite : Object
---@field texture      love.Image|nil   *(Read-only)* The current texture of the sprite, if it exists.
---@field texture_path string|nil       *(Read-only)* The string ID of the current texture, if it exists.
---@field frames       love.Image[]|nil *(Read-only)* The animation frames of the sprite, or `nil` if the texture has no frames.
---@field frame        number           *(Read-only)* The current frame of the sprite. Set with `Sprite:setFrame()`.
---
--- The base path of the sprite. \
--- Any calls to `Sprite:setSprite()` will have this path prepended to them,\
--- only checking for textures inside this folder. \
--- **Note**: *This path is still relative to `assets/sprites/`!*
---@field path string
---
--- Whether this sprite's `width` and `height` will be updated to the size of the texture. \
--- Defaults to `true` if a width and height is not specified in the constructor.
---@field use_texture_size boolean
---@field wrap_texture_x   boolean  If enabled, the texture will repeat horizontally across the screen.
---@field wrap_texture_y   boolean  If enabled, the texture will repeat vertically across the screen.
---
---@field loop          boolean      Whether the sprite will continuously loop its animation. (Defaults to `false`)
---@field playing       boolean      *(Read-only)* Whether an animation is currently playing.
---@field anim_speed    number       A multiplier for how fast the sprite animates. (Defaults to `1`)
---@field anim_sprite   string       *(Read-only)* The name of the sprite used in the current animation.
---@field anim_delay    number       *(Read-only)* The delay between frames in the current animation.
---@field anim_frames   number[]|nil *(Read-only)* A list of frame indexes the current animation loops through. If `nil`, the animation loops through all frames.
---@field anim_duration number       *(Read-only)* The duration of the current animation. If greater than 0, the animation will stop after this many seconds.
---@field anim_waiting  number       *(Read-only)* Set by the `wait` function of an animation routine. The amount of time left until the animation continues.
---
---@field anim_callback     Sprite.anim_callback|nil  A function that is called when the current animation finishes.
---@field anim_routine      thread|nil                *(Read-only)* The coroutine of the current sprite animation.
---@field anim_routine_func Sprite.anim_func|nil      *(Read-only)* The function of the current sprite animation.
---@field anim_wait_func    Sprite.wait_func          *(Read-only)* The function used to wait for the next frame of the animation.
---
---@overload fun(texture:string|love.Image|nil, x?:number, y?:number, width?:number, height?:number, path?:string) : Sprite
local Sprite, super = Class(Object)

function Sprite:init(texture, x, y, width, height, path)
    super.init(self, x, y, width, height)

    self.use_texture_size = (width == nil)
    self.path = path or ""

    self:setSprite(texture)

    self.wrap_texture_x = false
    self.wrap_texture_y = false

    self.frame = 1
    self.loop = false
    self.playing = false
    self.anim_speed = 1

    self.anim_routine_func = nil
    self.anim_routine = nil

    self.anim_sprite = ""
    self.anim_delay = 0
    self.anim_frames = nil
    self.anim_duration = -1
    self.anim_callback = nil
    self.anim_waiting = 0
    self.anim_wait_func = function(s) self.anim_waiting = s or 0; coroutine.yield() end

    self:resetCrossFade()
end

---@see Object.canDebugSelect
function Sprite:canDebugSelect()
    if self.debug_select then
        -- Make the sprite unselectable if it's the parent's "sprite" variable
        return not self.parent or self.parent.sprite ~= self
    else
        return self.debug_select
    end
end

--- Sets the wrapping mode of the sprite. \
--- The texture will repeat across the whole screen in the direction(s) specified.
---@param x  boolean  Whether the texture should repeat horizontally.
---@param y? boolean  Whether the texture should repeat vertically. If not specified, this will be the same as `x`.
function Sprite:setWrap(x, y)
    self.wrap_texture_x = x or false
    self.wrap_texture_y = y or (y == nil and x) or false
end

--- *(Called internally)* Updates the sprite's texture to its current frame. \
--- If the sprite has no frames, this will do nothing.
function Sprite:updateTexture()
    if self.frames then
        self:setTextureExact(self.frames[self.frame])
    end
end

---@return love.Image|nil texture  The current texture of the sprite, if it exists.
function Sprite:getTexture()
    return self.texture
end

--- Sets the current frame to a percentage between 0 - 1. \
--- If `progress` is outside of this range, it will wrap around.
---@param progress number  The percentage (0 - 1) of the animation to set the frame to.
function Sprite:setProgress(progress)
    self:setFrame(math.floor(#self.frames * progress) + 1)
end

--- *(Called internally)* Gets the full path to the texture this sprite should use \
--- given a path by `Sprite:setSprite()`. If this sprite's `path` is not empty, \
--- it will be prepended to the given path.
---@param name string  The relative path of the sprite to get the full path of.
function Sprite:getPath(name)
    if self.path ~= "" and name ~= "" then
        return self.path.."/"..name
    else
        return self.path..name
    end
end

---@param texture string  The texture to check the existence of, relative to this sprite's path.
---@return boolean exists  Whether the given texture exists.
function Sprite:hasSprite(texture)
    texture = self:getPath(texture)

    -- check this out
    return not not (Assets.getTexture(texture) or Assets.getFrames(texture))
end

---@param texture string  The texture to check against this sprite's current texture, relative to this sprite's path.
---@return boolean equal  Whether the textures are equal.
function Sprite:isSprite(texture)
    return self.texture_path == self:getPath(texture)
end

--- Sets the sprite to either a texture or an animation. \
--- If the given texture is a string or image, it will be passed into `Sprite:setSprite()`. \
--- If the given texture is a table, it will be passed into `Sprite:setAnimation()`.
---@param texture string|table|love.Image  The texture or animation to set the sprite to.
function Sprite:set(texture)
    if type(texture) == "table" then
        self:setAnimation(texture)
    else
        self:setSprite(texture)
    end
end

--- Sets the current sprite.
---@param texture string|table|love.Image  The texture to set the sprite to. If this is a string, it will be relative to this sprite's `path`.
---@param keep_anim? boolean  If `true`, this will not interrupt the current animation. Otherwise, any animation will be stopped.
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

--- *(Called internally)* Sets the current sprite to a single texture.  \
--- **Note**: *Ignores `path` and frames. Use `Sprite:setSprite()` instead.*
---@param texture string|love.Image  The texture to set the sprite to.
---@param keep_anim? boolean  If `true`, this will not interrupt the current animation. Otherwise, any animation will be stopped.
function Sprite:setTexture(texture, keep_anim)
    self.frames = nil
    self:setTextureExact(texture)
    if not keep_anim then
        self:stop()
    end
end

--- *(Called internally)* Sets the current sprite to a single texture. \
--- **Note**: *Only for internal overrides. Use `Sprite:setSprite()` instead.*
function Sprite:setTextureExact(texture)
    if type(texture) == "string" then
        self.texture = Assets.getTexture(texture)
    else
        self.texture = texture
    end
    if (not self.texture) and (texture ~= nil) then
        Kristal.Console:warn("Texture not found: " .. Utils.dump(texture))
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

--- Sets the frame of the current sprite. \
--- If the sprite has no frames, this will do nothing.
---@param frame number  The frame to set the sprite to. If this is outside of the range of frames, it will wrap around.
function Sprite:setFrame(frame)
    self.frame = ((frame - 1) % (self.frames and #self.frames or 1)) + 1
    self:updateTexture()
end

--- *(Called internally)* Sets the current sprite to a list of frames, and updates the texture.  \
--- **Note**: *Ignores `path` and single-frame textures. Use `Sprite:setSprite()` instead.*
---@param frames string|table  The frames to set the sprite to.
---@param keep_anim? boolean  If `true`, this will not interrupt the current animation. Otherwise, any animation will be stopped.
function Sprite:setFrames(frames, keep_anim)
    if type(frames) == "string" then
        self.frames = Assets.getFrames(frames)
    else
        self.frames = frames
    end
    if not keep_anim then
        self:stop()
    else
        self:setFrame(self.frame) -- this also clamps self.frame
    end
end

---@alias Sprite.wait_func     fun(seconds:number)
---@alias Sprite.anim_func     fun(wait:Sprite.wait_func)
---@alias Sprite.anim_callback fun(sprite:Sprite)

-- TODO: Document the rest of Sprite

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
    self.anim_routine_func = func
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
    self.anim_routine_func = nil
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

function Sprite:flash(offset_x, offset_y, layer)
    local flash = FlashFade(self.texture, offset_x or 0, offset_y or 0)
    flash.layer = layer or 100 -- TODO: Unhardcode?
    self:addChild(flash)
    return flash
end

function Sprite:setCrossFadeTexture(texture)
    if type(texture) == "string" then
        texture = self:getPath(texture)
        self.crossfade_texture = Assets.getTexture(texture)
    else
        self.crossfade_texture = texture
    end
    self.crossfade_texture_path = Assets.getTextureID(texture)
end

function Sprite:resetCrossFade()
    self.crossfade_alpha = 0
    self.crossfade_texture = nil
    self.crossfade_texture_path = nil
    self.crossfade_speed = 0
    self.crossfade_out = false
    self.crossfade_after = nil
end

function Sprite:crossFadeTo(texture, time, fade_out, after)
    self:crossFadeToSpeed(texture, (1 / (time or 1)) / 30 * (1 - self.crossfade_alpha), fade_out, after)
end

function Sprite:crossFadeToSpeed(texture, speed, fade_out, after)
    self:setCrossFadeTexture(texture)
    self.crossfade_speed = speed or 0.04
    self.crossfade_out = fade_out
    self.crossfade_after = function(self)
        self:setTexture(texture)
        self:resetCrossFade()
        if after then after(self) end
    end
end

function Sprite:onClone(src)
    super.onClone(self, src)

    self.anim_wait_func = function(s) self.anim_waiting = s or 0; coroutine.yield() end
    if self.anim_routine and coroutine.status(self.anim_routine) ~= "dead" then
        self.anim_routine = coroutine.create(self.anim_routine_func)
        coroutine.resume(self.anim_routine, self, self.anim_wait_func)
    end
end

function Sprite:update()
    if not self.anim_routine or coroutine.status(self.anim_routine) == "dead" then
        self:stop(true)
    end
    if self.crossfade_speed ~= 0 and self.crossfade_alpha ~= 1 then
        self.crossfade_alpha = Utils.approach(self.crossfade_alpha, 1, self.crossfade_speed*DTMULT)
        if self.crossfade_alpha == 1 and self.crossfade_after then
            self.crossfade_after(self)
        end
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

    super.update(self)
end

function Sprite:draw()
    local r,g,b,a = self:getDrawColor()
    local function drawSprite(...)
        if self.crossfade_alpha > 0 and self.crossfade_texture ~= nil then
            Draw.setColor(r, g, b, self.crossfade_out and Utils.lerp(a, 0, self.crossfade_alpha) or a)
            Draw.draw(self.texture, ...)

            Draw.setColor(r, g, b, Utils.lerp(0, a, self.crossfade_alpha))
            Draw.draw(self.crossfade_texture, ...)
        else
            Draw.setColor(r, g, b, a)
            Draw.draw(self.texture, ...)
        end
    end
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
                        drawSprite(x_offset + (i-1) * self.texture:getWidth(), y_offset + (j-1) * self.texture:getHeight())
                    end
                end
            elseif self.wrap_texture_x then
                for i = 1, wrap_width do
                    drawSprite(x_offset + (i-1) * self.texture:getWidth(), 0)
                end
            elseif self.wrap_texture_y then
                for j = 1, wrap_height do
                    drawSprite(0, y_offset + (j-1) * self.texture:getHeight())
                end
            end
        else
            drawSprite()
        end
    end

    super.draw(self)
end

return Sprite