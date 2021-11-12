local EnemyBattler, super = Class(Object)

function EnemyBattler:init(chara)
    super:init(self)
    self.name = "Test Enemy"

    self.layer = LAYERS["battlers"]

    if chara then
        self:setCharacter(chara)
    end

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.max_health = 100
    self.health = 100
    self.attack = 1
    self.defense = 0
    self.reward = 0

    self.tired = false
    self.mercy = 0

    self.done_state = nil

    self.waves = {}

    self.check = "Remember to change\nyour check text!"

    self.text = {
        "* Test Enemy is testing."
    }
    self.low_health_text = "* Enemy is feeling tired."

    self.dialogue = {
        "Test dialogue!"
    }

    self.acts = {
        {
            ["name"] = "Check",
            ["description"] = "",
            ["party"] = {}
        }
    }

    self.flash_siner = 0
    self.hurt_timer = 0

    self.last_selecting = false
end
function EnemyBattler:registerAct(name, description, party, tp)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["short"] = false
    }
    table.insert(self.acts, act)
end
function EnemyBattler:registerShortAct(name, description, party, tp)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["short"] = true
    }
    table.insert(self.acts, act)
end

function EnemyBattler:setText(...)  print("TODO: implement!") end -- TODO

function EnemyBattler:spare(pacify)
    Game.battle.spare_sound:stop()
    Game.battle.spare_sound:play()

    self.done_state = pacify and "PACIFIED" or "SPARED"

    self.sprite.color_mask = {1, 1, 1}
    self.sprite.color_mask_alpha = 0

    self:onSpared()

    local sparkle_timer = 0
    local parent = self.parent

    Game.battle.timer:during(5/30, function()
        self.sprite.color_mask_alpha = self.sprite.color_mask_alpha + 0.2 * DTMULT
        sparkle_timer = sparkle_timer + DTMULT
        if sparkle_timer >= 0.5 then
            local x, y = Utils.random(0, self.width), Utils.random(0, self.height)
            local sparkle = SpareSparkle(self:getRelativePos(x, y))
            sparkle.layer = self.layer + 0.001
            parent:addChild(sparkle)
            sparkle_timer = sparkle_timer - 0.5
        end
    end, function()
        self.sprite.color_mask_alpha = 1
        local img1 = AfterImage(self, 0.7, (1/25) * 0.7)
        local img2 = AfterImage(self, 0.4, (1/30) * 0.4)
        img1.speed_x = 4
        img2.speed_x = 8
        parent:addChild(img1)
        parent:addChild(img2)
        self:remove()
    end)

    Game.battle:removeEnemy(self)
end

function EnemyBattler:onSpared()
    self:setAnimation("spared")
end

function EnemyBattler:onSpareable()
    self:setAnimation("spared")
end

function EnemyBattler:addMercy(amount)
    if (self.mercy >= 100) then
        -- We're already at full mercy; do nothing.
        return
    end

    self.mercy = self.mercy + amount
    if (self.mercy < 0) then
        self.mercy = 0
    end

    if (self.mercy >= 100) then
        self:onSpareable()
        self.mercy = 100
    end

    if (amount > 0) then
        local pitch = 0.8
        if (amount < 99) then pitch = 1 end
        if (amount <= 50) then pitch = 1.2 end
        if (amount <= 25) then pitch = 1.4 end

        local src = Assets.playSound("snd_mercyadd", 0.8)
        src:setPitch(pitch)
    end

    self:statusMessage("mercy", amount)
end

function EnemyBattler:onMercy()
    if self.mercy >= 100 then
        self:spare()
        return true
    else
        self:addMercy(20)
        return false
    end
end

function EnemyBattler:fetchEncounterText()
    if self.health <= (self.max_health / 3) then
        return self.low_health_text
    end
    return Utils.pick(self.text)
end

function EnemyBattler:getEnemyDialogue()
    if self.dialogue_override then
        local dialogue = self.dialogue_override
        self.dialogue_override = nil
        return dialogue
    end
    return Utils.pick(self.dialogue)
end

function EnemyBattler:getNextWaves()
    return self.waves
end

function EnemyBattler:selectWave()
    local waves = self:getNextWaves()
    if waves and #waves > 0 then
        local wave = Utils.pick(waves)
        self.selected_wave = wave
        return wave
    end
end

function EnemyBattler:onCheck(battler) end

function EnemyBattler:onActStart(battler, name)
    battler:setAnimation("battle/act")
    local action = Game.battle:getCurrentAction()
    if action.party then
        for _,party_id in ipairs(action.party) do
            Game.battle:getPartyBattler(party_id):setAnimation("battle/act")
        end
    end
end

function EnemyBattler:onAct(battler, name)
    if name == "Check" then
        self:onCheck(battler)
        return "* " .. string.upper(self.name) .. " - " .. self.check
    end
end

function EnemyBattler:getAct(name)
    for _,act in ipairs(self.acts) do
        if act.name == name then
            return act
        end
    end
end

function EnemyBattler:getXAction(battler)
    return "Standard"
end

function EnemyBattler:isXActionShort(battler)
    return true
end

function EnemyBattler:hurt(amount, battler)
    Assets.playSound("snd_damage")

    self.health = self.health - amount
    self:statusMessage("damage", amount, battler and (battler.chara.dmg_color or battler.chara.color))

    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("hurt")

    self.overlay_sprite.shake_x = 9
    self.hurt_timer = 1
end

function EnemyBattler:heal(amount)
    Assets.playSound("snd_power")
    self.health = self.health + amount

    local offset = self.sprite:getOffset()
    local flash = FlashFade(self.sprite.texture, -offset[1], -offset[2])
    self:addChild(flash)

    if self.health > self.max_health then
        self.health = self.max_health
        self:statusMessage("msg", "max")
    else
        self:statusMessage("heal", amount, {0, 1, 0})
    end

    Game.battle.timer:every(1/30, function()
        for i = 1, 2 do
            local x = self.x + ((love.math.random() * self.width) - (self.width / 2)) * 2
            local y = self.y - (love.math.random() * self.height) * 2
            local sparkle = HealSparkle(x, y)
            self.parent:addChild(sparkle)
        end
    end, 4)
end

function EnemyBattler:statusMessage(type, arg, color)
    local hit_count = Game.battle.hit_count
    hit_count[self] = hit_count[self] or 0

    local x, y = self:getRelativePos(self.width/2, self.height/2)

    local percent = DamageNumber(type, arg, x + 4, y + 20 - (hit_count[self] * 20), color)
    self.parent:addChild(percent)

    hit_count[self] = hit_count[self] + 1
end

function EnemyBattler:setActor(actor)
    if type(actor) == "string" then
        self.actor = Registry.getActor(actor)
    else
        self.actor = actor
    end

    self.width = self.actor.width
    self.height = self.actor.height

    if self.sprite         then self:removeChild(self.sprite)         end
    if self.overlay_sprite then self:removeChild(self.overlay_sprite) end

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = "left"

    self.overlay_sprite = ActorSprite(self.actor)
    self.overlay_sprite.facing = "left"
    self.overlay_sprite.visible = false

    self:addChild(self.sprite)
    self:addChild(self.overlay_sprite)
end

function EnemyBattler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    self.overlay_sprite.visible = overlay
    self.sprite.visible = not overlay
end

-- Shorthand for convenience
function EnemyBattler:setAnimation(animation)
    return self.sprite:setAnimation(animation)
end

function EnemyBattler:setSprite(sprite, speed, loop, after)
    if not self.sprite then
        self.sprite = Sprite(sprite)
        self:addChild(self.sprite)
    else
        self.sprite:setSprite(sprite)
    end
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

function EnemyBattler:setCustomSprite(sprite, ox, oy, speed, loop, after)
    self.sprite:setCustomSprite(sprite, ox, oy)
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

function EnemyBattler:update(dt)
    if self.hurt_timer > 0 then
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, dt)

        if self.hurt_timer == 0 then
            self.overlay_sprite.shake_x = 0
            self:toggleOverlay(false)
        end
    end

    if Game.battle:isEnemySelected(self) then
        self.flash_siner = self.flash_siner + DTMULT
        self.sprite.color_mask = {1, 1, 1}
        self.sprite.color_mask_alpha = -math.cos(self.flash_siner / 5) * 0.4 + 0.6
        self.last_selecting = true
    elseif self.last_selecting then
        self.sprite.color_mask_alpha = 0
        self.last_selecting = false
    end

    super:update(self, dt)
end

return EnemyBattler