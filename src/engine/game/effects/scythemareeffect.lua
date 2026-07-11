---@class ScythemareEffectSettings
---@field index integer # The index of this ScythemareEffect in the current spell cast, used for pitching the sound effect. Defaults to 1
---@field joker boolean # Whether this ScythemareEffect is being cast by a character with the Devilsknife equipped or not. Defaults to false
---@field on_finish_func fun(obj: ScythemareEffect)? # A callback function that is called when the ScythemareEffect finishes. Optional
---@field play_sound boolean # Whether the spell_pacify sound effect should be played. Defaults to true
---@field laugh boolean # Whether the jevil_laugh sound effect should be played. Defaults to true

---@class ScythemareEffect : Object
---@overload fun(...) : ScythemareEffect
local ScythemareEffect, super = Class(Object)

---@param x number
---@param y number
---@param success boolean? # Whether the spell was successful or not. Defaults to true
---@param settings ScythemareEffectSettings? # Optional settings for the effect
function ScythemareEffect:init(x, y, success, settings)
    super.init(self, x, y, 48 * 3, 45 * 2)
    settings = settings or {}

    self:setOrigin(0.5, 0.5)

    self.success = success == nil or success

    self.joker = settings.joker or false
    self.play_sound = settings.play_sound == nil or settings.play_sound
    self.laugh = settings.laugh == nil or settings.laugh
    self.index = settings.index or 1

    self.timer = 0

    self.texture = Assets.getTexture(self.joker and "effects/scythemare_joker" or "effects/scythemare")

    self.on_finish_func = settings.on_finish_func

    self.swing_echo = false
    self.swing_echo_timer = 3
    self.swing_echo_vol = 1
end

function ScythemareEffect:updateEcho()
    if self.swing_echo_timer >= 3 then
        Assets.playSound("swing", self.swing_echo_vol, 1.5 + ((self.index - 1) * 0.25))
        self.swing_echo_timer = self.swing_echo_timer - 3
        self.swing_echo_vol = self.swing_echo_vol - 0.34

        if self.swing_echo_vol <= 0 then
            self.swing_echo = false
        end
    else
        self.swing_echo_timer = self.swing_echo_timer + DTMULT
    end
end

function ScythemareEffect:update()
    if self.swing_echo then
        self:updateEcho()
    end

    local old_timer = self.timer
    self.timer = self.timer + DTMULT

    if old_timer < 4 and self.timer >= 4 then
        Assets.playSound("impact")
    end

    if (old_timer < 13) and (self.timer >= 13) and self.play_sound then
        Assets.playSound("spell_pacify")
    end

    if (old_timer < 34) and (self.timer >= 34) then
        if self.success then
            self.swing_echo = true
        else
            Assets.playSound("bump", 2, MathUtils.random(0.5, 1.5))
        end

        if self.play_sound then
            Assets.stopSound("spell_pacify")
        end

        if self.joker and self.laugh then
            Assets.playSound("jevil_laugh")
        end
    end

    if (old_timer < 56) and self.timer >= 56 then
        if self.on_finish_func ~= nil then
            self.on_finish_func(self)
        end
    end

    if self.timer >= 64 then
        self:remove()
    end

    super.update(self)
end

function ScythemareEffect:draw()
    if self.timer < 6 then
        local size = MathUtils.lerp(4, 2, MathUtils.clamp(self.timer / 4, 0, 1))

        love.graphics.setColor(1, 1, 1, MathUtils.clamp(self.timer / 3, 0, 1))

        Draw.draw(self.texture, self.width / 2, self.height / 2, 0, size, size, 27, 23)
    elseif self.timer < 34 then
        local timer = self.timer - 6

        local fade_a = MathUtils.clamp(MathUtils.inverseLerp(8, 30, timer), 0, 1)
        local fade_b = MathUtils.clamp(MathUtils.inverseLerp(8, 20, timer), 0, 1)

        -- Both last_spin and last_alt_spin need to be their "previous values"
        -- DR just saves the previous value directly; we have unlimited FPS, so we can't do that
        -- So, just calculate it instead

        local last_spin = MathUtils.lerp(360, -90, Utils.ease(0, 1, (timer - 1) / 20, "in-out-cubic"))
        local spin = MathUtils.lerp(360, -90, Utils.ease(0, 1, timer / 20, "in-out-cubic"))
        local last_alt_spin = MathUtils.lerp(360, -10, Utils.ease(0, 1, (timer - 1) / 20, "in-out-cubic"))
        local alt_spin = MathUtils.lerp(360, -10, Utils.ease(0, 1, timer / 20, "in-out-cubic"))

        if timer >= 20 then
            last_spin = MathUtils.lerp(-20, 0, Utils.ease(0, 1, (timer - 21) / 8, "in-cubic"))
            spin = MathUtils.lerp(-20, 0, Utils.ease(0, 1, (timer - 20) / 8, "in-cubic"))
            last_alt_spin = MathUtils.lerp(-10, 0, Utils.ease(0, 1, (timer - 21) / 8, "in-cubic"))
            alt_spin = MathUtils.lerp(-10, 0, Utils.ease(0, 1, (timer - 20) / 8, "in-cubic"))
        end

        love.graphics.setColor(1, 1, 1, fade_b / 2)
        Draw.draw(Assets.getTexture("effects/spare/z"), self.width / 2, self.height / 2, -math.rad(last_alt_spin), 3, 3, 11, 10)
        love.graphics.setColor(1, 1, 1, fade_b)
        Draw.draw(Assets.getTexture("effects/spare/z"), self.width / 2, self.height / 2, -math.rad(alt_spin), 3, 3, 11, 10)

        if timer >= 20 then
            last_spin = MathUtils.lerp(-90, 10, Utils.ease(0, 1, (timer - 21) / 8, "in-cubic"))
            spin = MathUtils.lerp(-90, 10, Utils.ease(0, 1, (timer - 20) / 8, "in-cubic"))
        end

        love.graphics.setColor(1, 1, 1, (1 - fade_a) / 2)
        Draw.draw(self.texture, self.width / 2, self.height / 2, -math.rad(last_spin), 2, 2, 27, 23)
        love.graphics.setColor(1, 1, 1, 1 - fade_a)
        Draw.draw(self.texture, self.width / 2, self.height / 2, -math.rad(spin), 2, 2, 27, 23)
    else
        local timer = self.timer - 34

        local lerp = MathUtils.clamp(MathUtils.inverseLerp(6, 24, timer), 0, 1)
        local tween = Utils.ease(0, 20, lerp, "out-quad")

        if self.success then
            local alpha = MathUtils.clamp(MathUtils.lerp(1, 0, timer / 20), 0, 1)
            love.graphics.setColor(1, 1, 1, alpha)
            Draw.draw(Assets.getTexture("effects/spare/z_split_top"), self.width / 2 + tween, self.height / 2, 0, 3, 3, 11, 10)
            Draw.draw(Assets.getTexture("effects/spare/z_split_bottom"), self.width / 2 - tween, self.height / 2, 0, 3, 3, 11, 10)
            Draw.draw(Assets.getTexture("effects/spare/z_split_top"), self.width / 2 + (tween * 2), self.height / 2, 0, 3, 3, 11, 10)
            Draw.draw(Assets.getTexture("effects/spare/z_split_bottom"), self.width / 2 - (tween * 2), self.height / 2, 0, 3, 3, 11, 10)
        else
            local shake = 0

            if timer < 8 then
                shake = (8 - math.floor(timer)) * (((math.floor(timer) % 2) * 2) - 1)
                lerp = 0
                tween = 0
            else
                lerp = MathUtils.clamp(MathUtils.inverseLerp(8, 22, timer), 0, 1)
                tween = Utils.ease(0, 6, lerp, "in-quad")
            end

            Draw.setColor(1, 1, 1, 1 - lerp)
            Draw.draw(Assets.getTexture("effects/spare/z"), self.width / 2 + tween + shake, self.height / 2 + (tween * 10), -math.rad(-tween * 5), 3, 3, 11, 10)
        end

        if timer < 9 then
            Draw.setColor(1, 1, 1, 1)
            local frames = Assets.getFrames("effects/thrash_slash")
            Draw.draw(frames[math.floor(timer / 3) + 1], self.width / 2, self.height / 2, math.rad(90), 1, 2, 16, 48)
        end
    end

    Draw.setColor(1, 1, 1, 1)

    super.draw(self)
end

return ScythemareEffect
