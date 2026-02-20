--- An extension of `Sprite` that can integrate with an actor.
--- If an object defines an Actor, it will use this over `Sprite` for its sprite.
--- 
---@class ActorSprite : Sprite
---
---@field actor               Actor                               *(Read-only)* The actor associated with this sprite
---@field sprite              string?                             *(Read-only)* The current texture of the sprite, if it exists
---@field full_sprite         string?                             *(Read-only)* The full string path of the current texture, if it exists
---@field anim                table|string|function?              *(Read-only)* The current animation set on the sprite
---@field private facing      FacingDirection                     The sprite's current facing direction. See [`ActorSprite:getFacing()`](lua://ActorSprite.getFacing) and [`ActorSprite:setFacing()`](lua://ActorSprite.setFacing)
---@field private last_facing FacingDirection                     The direction the sprite was facing on the previous frame. See [`ActorSprite:getLastFacing()`](lua://ActorSprite.getLastFacing)
---@field sprite_options      table                               *(Read-only)*
---
---@field temp_anim           table|string|function?              *(Read-only)* The animation that will be set when the current temporary animation stops
---@field temp_sprite         string?                             *(Read-only)* The sprite that will be set when the current temporary animation stops 
---
---@field directional         boolean?                            *(Read-only)* Whether the current sprite changes based on the facing direction
---@field dir_sep             string?                             *(Read-only)* The separator the current sprite uses for its directional sprites. Either `"_"` or `"/"`
---
---@field offsets             table<string, [number, number]>     *(Read-only)* A table of offset positions for sprites (inherited from [`Actor.offsets`](lua://Actor.offsets))
---
---@field walking             boolean                             Whether the sprite is currently walking
---@field walk_speed          number                              The movement speed of the character attached to this sprite
---@field walk_frame          number                              *(Read-only)* The current frame of the walking animation
---@field walk_override       boolean                             *(Read-only)* Enables special update code for the walk animation
---
---@field aura                boolean                             Whether the sprite currently has a glowing aura (used for `ChaserEnemy` objects)
---@field aura_siner          number                              A timer used for the aura effect
---
---@field run_away            boolean                             Special draw mode for enemies running away from battle on defeat
---@field run_away_timer      number                              A timer used for the run away animation
---
---@field frozen              boolean                             Whether the sprite has a frozen overlay
---@field freeze_progress     number                              The percentage of the enemy that is frozen, as a number ranging from 0 to 1
---
---@field on_footstep         fun(sprite: Sprite, cycle: number)? A callback function that is run whenever the character is in the "step" part of their animation while walking
---
---@field last_flippable      boolean
---
---@overload fun(actor: string|Actor) : ActorSprite
local ActorSprite, super = Class(Sprite)

function ActorSprite:init(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end

    self.actor = actor
    self.sprite = nil
    self.full_sprite = nil
    self.anim = nil
    self.facing = "down"
    self.last_facing = "down"
    self.sprite_options = {}

    self.temp_anim = nil
    self.temp_sprite = nil

    self.directional = false
    self.dir_sep = "_"

    super.init(self, nil, 0, 0, actor:getWidth(), actor:getHeight(), actor:getSpritePath())

    self.offsets = actor.offsets or {}

    self.walking = false
    self.was_walking = false
    self.walk_speed = 4
    self.walk_frame = 2
    self.walk_override = false

    self.aura = false
    self.aura_siner = 0

    self.run_away = false
    self.run_away_timer = 0

    self.frozen = false
    self.freeze_progress = 1

    self.on_footstep = nil

    if actor then
        actor:onSpriteInit(self)
    end

    self:resetSprite()

    self.last_flippable = actor:getFlipDirection(self)
end

--- Resets this sprite to the default animation or sprite.
---@param ignore_actor_callback? boolean When set to `true`, will not call the actor's `preResetSprite()` function.
function ActorSprite:resetSprite(ignore_actor_callback)
    if not ignore_actor_callback and self.actor:preResetSprite(self) then
        return
    end
    if self.actor:getDefaultAnim() then
        self:setAnimation(self.actor:getDefaultAnim())
    elseif self.actor:getDefaultSprite() then
        self:setSprite(self.actor:getDefaultSprite())
    else
        self:set(self.actor:getDefault())
    end
    self.actor:onResetSprite(self)
end

--- *(Called internally)* Sets the current sprite to a single texture. \
--- **Note**: *Only for internal overrides. Use `Sprite:setSprite()` instead.*
function ActorSprite:setTextureExact(texture)
    super.setTextureExact(self, texture)

    self.sprite_options = self.actor:parseSpriteOptions(self.texture_path)
end

--- Sets or replaces the current actor on the sprite. \
--- *Will also reset the sprite through [`ActorSprite:setSprite()`](lua://ActorSprite.setSprite)*
---@param actor string|Actor
function ActorSprite:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    if self.actor and self.actor.id == actor.id then
        return
    end
    -- Clean up children (likely added by the actor)
    for _, child in ipairs(self.children) do
        self:removeChild(child)
    end
    self.actor = actor
    self.width = actor:getWidth()
    self.height = actor:getHeight()
    self.path = actor:getSpritePath()

    actor:onSpriteInit(self)

    self:resetSprite()
end

--- Sets the sprite relative to `assets/sprites`, with a custom offset.
---@param texture?      string  The path to the sprite to use, relative to `assets/sprites`
---@param ox?           number  The x-offset of the sprite
---@param oy?           number  The y-offset of the sprite
---@param keep_anim?    boolean
function ActorSprite:setCustomSprite(texture, ox, oy, keep_anim)
    self.path = ""
    if ox and oy then
        self.force_offset = { ox, oy }
    else
        self.force_offset = nil
    end
    self:_setSprite(texture, keep_anim)
end

--- Sets the sprite to either a texture or an animation \
--- If the current actor has an animation with a name matching `name`, it will be passed into [`ActorSprite:setAnimation()`](lua://ActorSprite.setAnimation). \
--- Otherwise, it will be passed into [`ActorSprite:setSprite()`](lua://ActorSprite.setSprite).
---@param name                      string|nil
---@param callback?                 fun(sprite: ActorSprite)
---@param ignore_actor_callback?    boolean
function ActorSprite:set(name, callback, ignore_actor_callback)
    if not ignore_actor_callback and self.actor:preSet(self, name, callback) then
        return
    end
    if self.actor:getAnimation(name) then
        self:setAnimation(name, callback)
    else
        self:setSprite(name)
        if callback then
            callback(self)
        end
    end
    self.actor:onSet(self, name, callback)
end

--- Sets the current sprite
---@param texture?                  string
---@param keep_anim?                boolean
---@param ignore_actor_callback?    boolean
function ActorSprite:setSprite(texture, keep_anim, ignore_actor_callback)
    if not ignore_actor_callback and self.actor:preSetSprite(self, texture, keep_anim) then
        return
    end
    self.walk_override = false
    self.path = self.actor:getSpritePath()
    self.force_offset = nil
    self:_setSprite(texture, keep_anim)

    self.actor:onSetSprite(self, texture, keep_anim)
end

--- *(Called internally)* Sets the current sprite
---@param texture?      string
---@param keep_anim?    boolean
function ActorSprite:_setSprite(texture, keep_anim)
    if not texture then
        self.texture = nil
        self.anim = nil
        self.temp_anim = nil
        self.temp_sprite = nil
        self.sprite = nil
        self.full_sprite = nil
        self.directional = false
        return
    end

    if type(texture) ~= "string" then
        error("Texture must be a string")
    end

    if not keep_anim then
        self.anim = nil

        self.temp_anim = nil
        self.temp_sprite = nil
    end

    self.sprite = texture
    self.full_sprite = self:getPath(texture)
    self.directional, self.dir_sep = self:isDirectional(self.full_sprite)

    if self.directional then
        super.setSprite(self, self:getDirectionalPath(self.sprite), keep_anim)
    else
        self.walk_frame = 1
        super.setSprite(self, self.sprite, keep_anim)
    end
end

--- Sets the animation of the current sprite. \
--- The animation specified in `anim` can be one of the following:
--- - `string` - The name of an animation defined on the sprite's current actor.
--- - `table` - a table of animation data. Refer to [`Sprite:setAnimation(anim)`](lua://Sprite.setAnimation) for how to use this, as well as the additional keys supported on `ActorSprite` listed below:
--- - - `temp: boolean` - Whether the previous aniamtion/sprite should be set once the new animation is stops (Defaults to `false`)
--- - `function` - An animation routine
---@param anim? table|string|function?
---@param callback? fun(sprite: ActorSprite)    A callback to run when the animation finishes
---@param ignore_actor_callback? boolean        Whether to skip calling [`Actor:preSetAnimation()`](lua://Actor.preSetAnimation)
---@return boolean?
function ActorSprite:setAnimation(anim, callback, ignore_actor_callback)
    if not ignore_actor_callback and self.actor:preSetAnimation(self, anim, callback) then
        return
    end
    local last_anim = self.temp_anim or self.anim
    local last_sprite = self.temp_sprite or self.sprite
    self.anim = anim
    if type(anim) == "string" then
        anim = self.actor:getAnimation(anim)
    end
    if anim then
        if type(anim) == "function" then
            anim = { anim }
        else
            anim = TableUtils.copy(anim)
        end
        if anim.temp then
            if last_anim then
                anim.callback = function(s) s:setAnimation(last_anim) end
                self.temp_anim = last_anim
            elseif last_sprite then
                anim.callback = function(s) s:setSprite(last_sprite) end
                self.temp_sprite = last_sprite
            end
        else
            self.temp_anim = nil
            self.temp_sprite = nil
        end
        if callback then
            if anim.callback then
                local old_callback = anim.callback
                anim.callback = function(s) old_callback(s); callback(s) end
            else
                anim.callback = callback
            end
        end
        super.setAnimation(self, anim)
        if not ignore_actor_callback then
            self.actor:onSetAnimation(self, anim, callback)
        end
        return true
    else
        self.temp_anim = nil
        self.temp_sprite = nil
        if callback then
            callback(self)
        end
        return false
    end
end

--- Sets the current sprite and starts animating it based on [`walk_speed`](lua://ActorSprite.walk_speed) and [`walking`](lua://ActorSprite.walking)
---@param texture string
function ActorSprite:setWalkSprite(texture)
    self:setSprite(texture)
    self.walk_override = true
end

--- Whether this sprite can talk using it's current sprite
---@return boolean can_talk     Whether a talksprite is defined
---@return number talk_speed    The speed at which the talk sprite should animate, in seconds
function ActorSprite:canTalk()
    for _, sprite in ipairs(self.sprite_options) do
        if self.actor:hasTalkSprite(sprite) then
            return true, self.actor:getTalkSpeed(sprite)
        end
    end
    return false, 0.25
end

--- Gets the facing direction of the current sprite
---@return FacingDirection
function ActorSprite:getFacing()
    return self.facing
end

--- Sets the facing direction of the current sprite
---@param facing FacingDirection
function ActorSprite:setFacing(facing)
    self.facing = facing
    self:updateDirection()
end

--- *(Called internally)* Updates the current sprite to match the current facing direction
function ActorSprite:updateDirection()
    local facing = self:getFacing()
    if self.directional and self:getLastFacing() ~= facing then
        super.setSprite(self, self:getDirectionalPath(self.sprite), true)
    end
    self.last_facing = facing
end

--- Gets the previous facing direction
function ActorSprite:getLastFacing()
    return self.last_facing
end

--- Checks whether `sprite` matches the sprite's current texture
---@param sprite string
---@return boolean
function ActorSprite:isSprite(sprite)
    return TableUtils.contains(self.sprite_options, sprite)
end

--- Selects from the given table `tbl` the relevant value for the current sprite, if it exists
---@param tbl table
---@return any
function ActorSprite:getValueForSprite(tbl)
    for _, sprite in ipairs(self.sprite_options) do
        if tbl[sprite] then
            return tbl[sprite]
        end
    end
end

--- *(Called internally)* Checks whether a particular `texture` has sprites defined for multiple facing directions \
--- **Note:** Assumes that all four directions are always defined
---@param texture string
---@return boolean? directional
---@return string? separator
function ActorSprite:isDirectional(texture)
    if not Assets.getTexture(texture) and not Assets.getFrames(texture) then
        if Assets.getTexture(texture .. "_left") or Assets.getFrames(texture .. "_left") then
            return true, "_"
        elseif Assets.getTexture(texture .. "/left") or Assets.getFrames(texture .. "/left") then
            return true, "/"
        end
    end
end

--- *(Called internally)* Gets the path for a directional sprite based on the current facing direction
---@param sprite string
---@return string new_sprite
function ActorSprite:getDirectionalPath(sprite)
    if sprite ~= "" then
        return sprite .. self.dir_sep .. self:getFacing()
    else
        return self.facing
    end
end

---@return [number, number]
function ActorSprite:getOffset()
    local offset = { 0, 0 }
    if self.force_offset then
        offset = self.force_offset
    else
        for _, sprite in ipairs(self.sprite_options) do
            if self.actor:hasOffset(sprite) then
                offset = { self.actor:getOffset(sprite) }
                break
            end
        end
        --[[local frames_for = Assets.getFramesFor(self.full_sprite)
        local frames_for_dir = self.directional and Assets.getFramesFor(self:getDirectionalPath(self.full_sprite))
        offset = self.offsets[self.sprite] or (frames_for and self.offsets[frames_for]) or
            (self.directional and (self.offsets[self:getDirectionalPath(self.sprite)] or (frames_for_dir and self.offsets[frames_for_dir])))
            or {0, 0}]]
    end
    return offset
end

function ActorSprite:update()
    if self.actor:preSpriteUpdate(self) then
        return
    end

    local flip_dir
    for _, sprite in ipairs(self.sprite_options) do
        flip_dir = self.actor:getFlipDirection(sprite)
        if flip_dir then break end
    end

    if flip_dir then
        if not self.directional then
            local opposite = flip_dir == "right" and "left" or "right"
            if self:getFacing() == flip_dir then
                self.flip_x = true
            elseif self:getFacing() == opposite then
                self.flip_x = false
            end
        else
            self.flip_x = false
        end
        self.last_flippable = true
    elseif self.last_flippable then
        self.last_flippable = false
        self.flip_x = false
    end

    if not self.playing then
        if self.directional or self.walk_override then
            local should_do_walk_animation = false

            if self.walking then
                -- If we're holding a movement key, or this actor is walking 
                -- for any reason, we want to do the walk animation.
                should_do_walk_animation = true
            elseif self.frames then
                -- If we're NOT walking, BUT we're "stepping", continue the
                -- animation until we're done stepping.
                should_do_walk_animation = self.frame % 2 == 0
            end

            if should_do_walk_animation then
                -- If we should process the walking animation, do so.

                -- Old frame for reference
                local old_frame = math.floor(self.walk_frame)

                -- Increase our walking frame
                self.walk_frame = self.walk_frame + (DT * (self.walk_speed > 0 and self.walk_speed or 1))

                -- Our current frame we should actually render using
                local floored_frame = math.floor(self.walk_frame)

                -- Set the frame to that
                self:setFrame(floored_frame)

                -- If we've changed frames into a "step" frame, call the footstep callback
                if ((old_frame ~= floored_frame) or (self.walking and not self.was_walking)) and (self.on_footstep ~= nil) and (self.frame % 2 == 0) then
                    self.on_footstep(self, ((math.floor(floored_frame / 2) - 1) % 2) + 1)
                end
            elseif self.frames then
                -- We should NOT do the walking animation right now, despite having a walking sprite, so reset.
                self:setFrame(1)
            end
        end

        self:updateDirection()
    end

    self.was_walking = self.walking

    if self.aura then
        self.aura_siner = self.aura_siner + 0.25 * DTMULT
    end

    if self.run_away then
        self.run_away_timer = self.run_away_timer + DTMULT
    end

    super.update(self)

    self.actor:onSpriteUpdate(self)
end

---@param transform love.Transform
function ActorSprite:applyTransformTo(transform)
    super.applyTransformTo(self, transform)
    local offset = self:getOffset()
    transform:translate(offset[1], offset[2])
end

function ActorSprite:draw()
    if self.actor:preSpriteDraw(self) then
        return
    end

    if self.texture and self.run_away then
        local r, g, b, a = self:getDrawColor()
        for i = 0, 80 do
            local alph = a * 0.4
            Draw.setColor(r, g, b, ((alph - (self.run_away_timer / 8)) + (i / 200)))
            Draw.draw(self.texture, i * 2, 0)
        end
        return
    end

    if self.texture and self.aura then
        -- Use additive blending if the enemy is not being drawn to a canvas
        if love.graphics.getCanvas() == SCREEN_CANVAS then
            love.graphics.setBlendMode("add")
        end

        local sprite_width = self.texture:getWidth()
        local sprite_height = self.texture:getHeight()

        for i = 1, 5 do
            local aura = (i * 9) + ((self.aura_siner * 3) % 9)
            local aurax = (aura * 0.75) + (math.sin(aura / 4) * 4)
            --var auray = (45 * scr_ease_in((aura / 45), 1))
            local auray = 45 * Ease.inSine(aura / 45, 0, 1, 1)
            local aurayscale = math.min(1, 80 / sprite_height)

            Draw.setColor(1, 0, 0, (1 - (auray / 45)) * 0.5)
            Draw.draw(self.texture, -((aurax / 180) * sprite_width), -((auray / 82) * sprite_height * aurayscale), 0, 1 + ((aurax / 36) * 0.5), 1 + (((auray / 36) * aurayscale) * 0.5))
        end

        love.graphics.setBlendMode("alpha")

        local xmult = math.min((70 / sprite_width) * 4, 4)
        local ymult = math.min((80 / sprite_height) * 5, 5)
        local ysmult = math.min((80 / sprite_height) * 0.2, 0.2)

        Draw.setColor(1, 0, 0, 0.2)
        Draw.draw(self.texture, (sprite_width / 2) + (math.sin(self.aura_siner / 5) * xmult) / 2, (sprite_height / 2) + (math.cos(self.aura_siner / 5) * ymult) / 2, 0, 1, 1 + (math.sin(self.aura_siner / 5) * ysmult) / 2, sprite_width / 2, sprite_height / 2)
        Draw.draw(self.texture, (sprite_width / 2) - (math.sin(self.aura_siner / 5) * xmult) / 2, (sprite_height / 2) - (math.cos(self.aura_siner / 5) * ymult) / 2, 0, 1, 1 - (math.sin(self.aura_siner / 5) * ysmult) / 2, sprite_width / 2, sprite_height / 2)

        local last_shader = love.graphics.getShader()
        love.graphics.setShader(Kristal.Shaders["AddColor"])

        Kristal.Shaders["AddColor"]:send("inputcolor", { 1, 0, 0 })
        Kristal.Shaders["AddColor"]:send("amount", 1)

        Draw.setColor(1, 1, 1, 0.3)
        Draw.draw(self.texture, 1, 0)
        Draw.draw(self.texture, -1, 0)
        Draw.draw(self.texture, 0, 1)
        Draw.draw(self.texture, 0, -1)

        love.graphics.setShader(last_shader)

        Draw.setColor(self:getDrawColor())
    end

    super.draw(self)

    if self.texture and self.frozen then
        if self.freeze_progress < 1 then
            Draw.pushScissor()
            Draw.scissorPoints(nil, self.texture:getHeight() * (1 - self.freeze_progress), nil, nil)
        end

        local last_shader = love.graphics.getShader()
        local shader = Kristal.Shaders["AddColor"]
        love.graphics.setShader(shader)
        shader:send("inputcolor", { 0.8, 0.8, 0.9 })
        shader:send("amount", 1)

        local r, g, b, a = self:getDrawColor()

        Draw.setColor(0, 0, 1, a * 0.8)
        Draw.draw(self.texture, -1, -1)
        Draw.setColor(0, 0, 1, a * 0.4)
        Draw.draw(self.texture, 1, -1)
        Draw.draw(self.texture, -1, 1)
        Draw.setColor(0, 0, 1, a * 0.8)
        Draw.draw(self.texture, 1, 1)

        love.graphics.setShader(last_shader)

        love.graphics.setBlendMode("add")
        Draw.setColor(0.8, 0.8, 0.9, a * 0.4)
        Draw.draw(self.texture)
        love.graphics.setBlendMode("alpha")

        if self.freeze_progress < 1 then
            Draw.popScissor()
        end
    end

    self.actor:onSpriteDraw(self)
end

return ActorSprite
