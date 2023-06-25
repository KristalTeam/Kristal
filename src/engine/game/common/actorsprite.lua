---@class ActorSprite : Sprite
---@overload fun(...) : ActorSprite
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

function ActorSprite:setTextureExact(texture)
    super.setTextureExact(self, texture)

    self.sprite_options = self.actor:parseSpriteOptions(self.texture_path)
end

function ActorSprite:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    if self.actor and self.actor.id == actor.id then
        return
    end
    -- Clean up children (likely added by the actor)
    for _,child in ipairs(self.children) do
        self:removeChild(child)
    end
    self.actor = actor
    self.width = actor:getWidth()
    self.height = actor:getHeight()
    self.path = actor:getSpritePath()

    actor:onSpriteInit(self)

    self:resetSprite()
end

function ActorSprite:setCustomSprite(texture, ox, oy, keep_anim)
    self.path = ""
    if ox and oy then
        self.force_offset = {ox, oy}
    else
        self.force_offset = nil
    end
    self:_setSprite(texture, keep_anim)
end

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
            anim = {anim}
        else
            anim = Utils.copy(anim)
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

function ActorSprite:setWalkSprite(texture)
    self:setSprite(texture)
    self.walk_override = true
end

function ActorSprite:canTalk()
    for _,sprite in ipairs(self.sprite_options) do
        if self.actor:hasTalkSprite(sprite) then
            return true, self.actor:getTalkSpeed(sprite)
        end
    end
    return false, 0.25
end

function ActorSprite:setFacing(facing)
    self.facing = facing
    self:updateDirection()
end

function ActorSprite:updateDirection()
    if self.directional and self.last_facing ~= self.facing then
        super.setSprite(self, self:getDirectionalPath(self.sprite), true)
    end
    self.last_facing = self.facing
end

function ActorSprite:isSprite(sprite)
    return Utils.containsValue(self.sprite_options, sprite)
end

function ActorSprite:getValueForSprite(tbl)
    for _,sprite in ipairs(self.sprite_options) do
        if tbl[sprite] then
            return tbl[sprite]
        end
    end
end

function ActorSprite:isDirectional(texture)
    if not Assets.getTexture(texture) and not Assets.getFrames(texture) then
        if Assets.getTexture(texture.."_left") or Assets.getFrames(texture.."_left") then
            return true, "_"
        elseif Assets.getTexture(texture.."/left") or Assets.getFrames(texture.."/left") then
            return true, "/"
        end
    end
end

function ActorSprite:getDirectionalPath(sprite)
    if sprite ~= "" then
        return sprite..self.dir_sep..self.facing
    else
        return self.facing
    end
end

function ActorSprite:getOffset()
    local offset = {0, 0}
    if self.force_offset then
        offset = self.force_offset
    else
        for _,sprite in ipairs(self.sprite_options) do
            if self.actor:hasOffset(sprite) then
                offset = {self.actor:getOffset(sprite)}
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
    for _,sprite in ipairs(self.sprite_options) do
        flip_dir = self.actor:getFlipDirection(sprite)
        if flip_dir then break end
    end

    if flip_dir then
        if not self.directional then
            local opposite = flip_dir == "right" and "left" or "right"
            if self.facing == flip_dir then
                self.flip_x = true
            elseif self.facing == opposite then
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
        local floored_frame = math.floor(self.walk_frame)
        if floored_frame ~= self.walk_frame or ((self.directional or self.walk_override) and self.walking) then
            self.walk_frame = Utils.approach(self.walk_frame, floored_frame + 1, DT * (self.walk_speed > 0 and self.walk_speed or 1))
            local last_frame = self.frame
            self:setFrame(floored_frame)
            if self.frame ~= last_frame and self.on_footstep and self.frame % 2 == 0 then
                self.on_footstep(self, math.floor(self.frame/2))
            end
        elseif (self.directional or self.walk_override) and self.frames and not self.walking then
            self:setFrame(1)
        end

        self:updateDirection()
    end

    if self.aura then
        self.aura_siner = self.aura_siner + 0.25 * DTMULT
    end

    if self.run_away then
        self.run_away_timer = self.run_away_timer + DTMULT
    end

    super.update(self)

    self.actor:onSpriteUpdate(self)
end

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
        local r,g,b,a = self:getDrawColor()
        for i = 0, 80 do
            local alph = a * 0.4
            Draw.setColor(r,g,b, ((alph - (self.run_away_timer / 8)) + (i / 200)))
            Draw.draw(self.texture, i * 2, 0)
        end
        return
    end

    if self.texture and self.aura then
        for i = 1, 5 do
            local aura = (i * 9) + ((self.aura_siner * 3) % 9)
            local aurax = (aura * 0.75) + (math.sin(aura / 4) * 4)
            --var auray = (45 * scr_ease_in((aura / 45), 1))
            local auray = 45 * Ease.inSine(aura / 45, 0, 1, 1)
            local aurayscale = math.min(1, 80 / self.texture:getHeight())

            Draw.setColor(1, 0, 0, (1 - (auray / 45)) * 0.5)
            Draw.draw(self.texture, -((aurax / 180) * self.texture:getWidth()), -((auray / 82) * self.texture:getHeight() * aurayscale), 0, 1 + ((aurax/36) * 0.5), 1 + (((auray / 36) * aurayscale) * 0.5))
        end
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
        shader:send("inputcolor", {0.8, 0.8, 0.9})
        shader:send("amount", 1)

        local r,g,b,a = self:getDrawColor()

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