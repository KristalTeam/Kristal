local EnemyBattler, super = Class(Battler)

function EnemyBattler:init(chara)
    super:init(self)
    self.name = "Test Enemy"

    if chara then
        self:setCharacter(chara)
    end

    self.max_health = 100
    self.health = 100
    self.attack = 1
    self.defense = 0

    self.money = 0
    self.experience = 0 -- currently useless, maybe in later chapters?

    self.tired = false
    self.mercy = 0

    self.spare_points = 0

    -- Whether the enemy runs/slides away when defeated/spared
    self.exit_on_defeat = true

    -- Whether this enemy is automatically spared at full mercy
    self.auto_spare = false

    -- Whether this enemy can be frozen
    self.can_freeze = true

    self.done_state = nil

    self.waves = {}

    self.check = "Remember to change\nyour check text!"

    self.text = {}

    self.low_health_text = "* Enemy is feeling tired."
    self.tired_percentage = 0.5

    self.dialogue = {}

    self.acts = {
        {
            ["name"] = "Check",
            ["description"] = "",
            ["party"] = {}
        }
    }

    self.hurt_timer = 0
    self.comment = ""
    self.icons = {}
    self.defeated = false
end

function EnemyBattler:setTired(bool)
    self.tired = bool
    if self.tired then
        self.comment = "(Tired)"
    else
        self.comment = ""
    end
end

function EnemyBattler:registerAct(name, description, party, tp, highlight)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,chara in ipairs(Game.party) do
                table.insert(party, chara.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = nil,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = false,
    }
    table.insert(self.acts, act)
end
function EnemyBattler:registerShortAct(name, description, party, tp, highlight)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,battler in ipairs(Game.battle.party) do
                table.insert(party, battler.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = nil,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = true
    }
    table.insert(self.acts, act)
end

function EnemyBattler:registerActFor(char, name, description, party, tp, highlight)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,chara in ipairs(Game.party) do
                table.insert(party, chara.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = char,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = false
    }
    table.insert(self.acts, act)
end
function EnemyBattler:registerShortActFor(char, name, description, party, tp, highlight)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,battler in ipairs(Game.battle.party) do
                table.insert(party, battler.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = char,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = true
    }
    table.insert(self.acts, act)
end

function EnemyBattler:setText(...)  print("TODO: implement!") end -- TODO

function EnemyBattler:spare(pacify)
    if self.exit_on_defeat then
        Game.battle.spare_sound:stop()
        Game.battle.spare_sound:play()

        local spare_flash = self:addFX(ColorMaskFX())
        spare_flash.amount = 0

        local sparkle_timer = 0
        local parent = self.parent

        Game.battle.timer:during(5/30, function()
            spare_flash.amount = spare_flash.amount + 0.2 * DTMULT
            sparkle_timer = sparkle_timer + DTMULT
            if sparkle_timer >= 0.5 then
                local x, y = Utils.random(0, self.width), Utils.random(0, self.height)
                local sparkle = SpareSparkle(self:getRelativePos(x, y))
                sparkle.layer = self.layer + 0.001
                parent:addChild(sparkle)
                sparkle_timer = sparkle_timer - 0.5
            end
        end, function()
            spare_flash.amount = 1
            local img1 = AfterImage(self, 0.7, (1/25) * 0.7)
            local img2 = AfterImage(self, 0.4, (1/30) * 0.4)
            img1.physics.speed_x = 4
            img2.physics.speed_x = 8
            parent:addChild(img1)
            parent:addChild(img2)
            self:remove()
        end)
    end

    self:defeat(pacify and "PACIFIED" or "SPARED", false)
    self:onSpared()
end

function EnemyBattler:onSpared()
    self:setAnimation("spared")
end

function EnemyBattler:onSpareable()
    self:setAnimation("spared")
end

function EnemyBattler:addMercy(amount)
    if self.mercy >= 100 then
        -- We're already at full mercy; do nothing.
        return
    end

    self.mercy = self.mercy + amount
    if self.mercy < 0 then
        self.mercy = 0
    end

    if self.mercy >= 100 then
        self:onSpareable()
        self.mercy = 100
        if self.auto_spare then
            self:spare(false)
        end
    end

    if amount > 0 then
        local pitch = 0.8
        if amount < 99 then pitch = 1 end
        if amount <= 50 then pitch = 1.2 end
        if amount <= 25 then pitch = 1.4 end

        local src = Assets.playSound("snd_mercyadd", 0.8)
        src:setPitch(pitch)

        self:statusMessage("mercy", amount)
    else
        self:statusMessage("msg", "miss")
    end
end

function EnemyBattler:onMercy()
    if self.mercy >= 100 then
        self:spare()
        return true
    else
        self:addMercy(self.spare_points)
        return false
    end
end

function EnemyBattler:getEncounterText()
    if self.health <= (self.max_health * self.tired_percentage) then
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
    if self.wave_override then
        local wave = self.wave_override
        self.wave_override = nil
        return {wave}
    end
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

function EnemyBattler:onTurnStart() end
function EnemyBattler:onTurnEnd() end

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
    return false
end

function EnemyBattler:hurt(amount, battler, on_defeat)
    self.health = self.health - amount
    self:statusMessage("damage", amount, battler and {battler.chara:getDamageColor()})

    self.hurt_timer = 1
    self:onHurt(amount, battler)

    self:checkHealth(on_defeat)
end

function EnemyBattler:checkHealth(on_defeat)
    -- on_defeat is optional
    if self.health <= 0 then
        self.health = 0

        if not self.defeated then
            if on_defeat then
                on_defeat(self, amount, battler)
            else
                self:onDefeat(amount, battler)
            end
        end
    end
end

function EnemyBattler:getAttackTension(points)
    -- In Deltarune, this is always 10*2.5, except for JEVIL where it's 15*2.5
    return points / 25
end

function EnemyBattler:getAttackDamage(damage, battler)
    return damage
end

function EnemyBattler:onHurt(damage, battler)
    if self.overlay_sprite:setAnimation("hurt") then
        self:toggleOverlay(true)
        self.overlay_sprite.shake_x = 9
    else
        self:toggleOverlay(false)
        self.sprite.shake_x = 9
    end

    if self.health <= (self.max_health * self.tired_percentage) then
        self:setTired(true)
    end
end

function EnemyBattler:onHurtEnd()
    self:getActiveSprite().shake_x = 0
    self:toggleOverlay(false)
end

function EnemyBattler:onDefeat(damage, battler)
    if self.exit_on_defeat then
        self:onDefeatRun(damage, battler)
    else
        self.sprite:setAnimation("defeat")
    end
end

function EnemyBattler:onDefeatRun(damage, battler)
    self.hurt_timer = -1
    self.defeated = true

    Assets.playSound("snd_defeatrun")

    local sweat = Sprite("effects/defeat/sweat")
    sweat:setOrigin(0.5, 0.5)
    sweat:play(5/30, true)
    sweat.layer = 100
    self:addChild(sweat)

    Game.battle.timer:after(15/30, function()
        sweat:remove()
        self:getActiveSprite().run_away = true

        Game.battle.timer:after(15/30, function()
            self:remove()
        end)
    end)

    self:defeat("VIOLENCED", true)
end

function EnemyBattler:onDefeatFatal(damage, battler)
    self.hurt_timer = -1

    Assets.playSound("snd_deathnoise")

    local sprite = self:getActiveSprite()

    sprite.visible = false
    sprite.shake_x = 0

    local death_x, death_y = sprite:getRelativePos(0, 0, self)
    local death = FatalEffect(sprite:getTexture(), death_x, death_y, function() self:remove() end)
    death:setColor(sprite:getDrawColor())
    death:setScale(sprite:getScale())
    self:addChild(death)

    self:defeat("KILLED", true)
end

function EnemyBattler:heal(amount)
    Assets.stopAndPlaySound("snd_power")
    self.health = self.health + amount

    self:flash()

    if self.health >= self.max_health then
        self.health = self.max_health
        self:statusMessage("msg", "max")
    else
        self:statusMessage("heal", amount, {0, 1, 0})
    end

    self:sparkle()
end

function EnemyBattler:freeze()
    if not self.can_freeze then
        self:onDefeatRun()
    end

    Assets.playSound("snd_petrify")

    self:toggleOverlay(true)
    if not self.overlay_sprite:setAnimation("frozen") then
        self.overlay_sprite:setAnimation("hurt")
    end
    self.overlay_sprite.shake_x = 0

    self.hurt_timer = -1

    self.overlay_sprite.frozen = true
    self.overlay_sprite.freeze_progress = 0

    Game.battle.timer:tween(20/30, self.overlay_sprite, {freeze_progress = 1})

    Game.battle.money = Game.battle.money + 24
    self:defeat("FROZEN", true)
end

function EnemyBattler:statusMessage(...)
    super:statusMessage(self, self.width/2, self.height/2, ...)
end

function EnemyBattler:defeat(reason, violent)
    self.done_state = reason or "DEFEATED"

    if violent then
        Game.battle.used_violence = true
    end

    Game.battle.money = Game.battle.money + self.money
    Game.battle.xp = Game.battle.xp + self.experience

    Game.battle:removeEnemy(self, true)
end

function EnemyBattler:setActor(actor)
    if type(actor) == "string" then
        self.actor = Registry.createActor(actor)
    else
        self.actor = actor
    end

    self.width = self.actor:getWidth()
    self.height = self.actor:getHeight()

    if self.sprite         then self:removeChild(self.sprite)         end
    if self.overlay_sprite then self:removeChild(self.overlay_sprite) end

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = "left"
    self.sprite.inherit_color = true

    self.overlay_sprite = ActorSprite(self.actor)
    self.overlay_sprite.facing = "left"
    self.overlay_sprite.visible = false
    self.overlay_sprite.inherit_color = true

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

function EnemyBattler:update()
    if self.hurt_timer > 0 then
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, DT)

        if self.hurt_timer == 0 then
            self:onHurtEnd()
        end
    end

    super:update(self)
end

return EnemyBattler