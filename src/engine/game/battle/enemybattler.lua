---@class EnemyBattler : Battler
---@overload fun(...) : EnemyBattler
local EnemyBattler, super = Class(Battler)

function EnemyBattler:init(actor, use_overlay)
    super.init(self)
    self.name = "Test Enemy"

    if actor then
        self:setActor(actor, use_overlay)
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

    -- Whether this enemy can be selected or not
    self.selectable = true

    -- Whether mercy is disabled for this enemy, like snowgrave Spamton NEO.
    -- This only affects the visual mercy bar.
    self.disable_mercy = false

    self.done_state = nil

    self.waves = {}

    self.check = "Remember to change\nyour check text!"

    self.text = {}

    self.low_health_text = nil
    self.tired_text = nil
    self.spareable_text = nil

    self.tired_percentage = 0.5
    self.low_health_percentage = 0.5

    -- Speech bubble style - defaults to "round" or "cyber", depending on chapter
    -- This is set to nil in `battler.lua` as well, but it's here for completion's sake.
    self.dialogue_bubble = nil

    -- The offset for the speech bubble, also set in `battler.lua`
    self.dialogue_offset = {0, 0}

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

    self.current_target = "ANY"
end

function EnemyBattler:setTired(bool)
    self.tired = bool
    if self.tired then
        self.comment = "(Tired)"
    else
        self.comment = ""
    end
end

function EnemyBattler:registerAct(name, description, party, tp, highlight, icons)
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
        ["icons"] = icons
    }
    table.insert(self.acts, act)
    return act
end

function EnemyBattler:registerShortAct(name, description, party, tp, highlight, icons)
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
        ["short"] = true,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
    return act
end

function EnemyBattler:registerActFor(char, name, description, party, tp, highlight, icons)
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
        ["short"] = false,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
end

function EnemyBattler:registerShortActFor(char, name, description, party, tp, highlight, icons)
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
        ["short"] = true,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
end

function EnemyBattler:removeAct(name)
    for i,act in ipairs(self.acts) do
        if act.name == name then
            table.remove(self.acts, i)
            break
        end
    end
end

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
            img1:addFX(ColorMaskFX())
            img2:addFX(ColorMaskFX())
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

function EnemyBattler:getSpareText(battler, success)
    if success then
        return "* " .. battler.chara:getName() .. " spared " .. self.name .. "!"
    else
        local text = "* " .. battler.chara:getName() .. " spared " .. self.name .. "!\n* But its name wasn't [color:yellow]YELLOW[color:reset]..."
        if self.tired then
            local found_spell = nil
            for _,party in ipairs(Game.battle.party) do
                for _,spell in ipairs(party.chara:getSpells()) do
                    if spell:hasTag("spare_tired") then
                        found_spell = spell
                        break
                    end
                end
                if found_spell then
                    text = {text, "* (Try using "..party.chara:getName().."'s [color:blue]"..found_spell:getCastName().."[color:reset]!)"}
                    break
                end
            end
            if not found_spell then
                text = {text, "* (Try using [color:blue]ACTs[color:reset]!)"}
            end
        end
        return text
    end
end

function EnemyBattler:canSpare()
    return self.mercy >= 100
end

function EnemyBattler:onSpared()
    self:setAnimation("spared")
end

function EnemyBattler:onSpareable()
    self:setAnimation("spared")
end

function EnemyBattler:addMercy(amount)
    if (amount >= 0 and self.mercy >= 100) or (amount < 0 and self.mercy <= 0) then
        -- We're already at full mercy and trying to add more; do nothing.
        -- Also do nothing if trying to remove from an empty mercy bar.
        return
    end

    self.mercy = self.mercy + amount
    if self.mercy < 0 then
        self.mercy = 0
    end

    if self.mercy >= 100 then
        self.mercy = 100
    end

    if self:canSpare() then
        self:onSpareable()
        if self.auto_spare then
            self:spare(false)
        end
    end

    if Game:getConfig("mercyMessages") then
        if amount == 0 then
            self:statusMessage("msg", "miss")
        else
            if amount > 0 then
                local pitch = 0.8
                if amount < 99 then pitch = 1 end
                if amount <= 50 then pitch = 1.2 end
                if amount <= 25 then pitch = 1.4 end

                local src = Assets.playSound("mercyadd", 0.8)
                src:setPitch(pitch)
            end

            self:statusMessage("mercy", amount)
        end
    end
end

function EnemyBattler:onMercy(battler)
    if self:canSpare() then
        self:spare()
        return true
    else
        self:addMercy(self.spare_points)
        return false
    end
end

function EnemyBattler:mercyFlash(color)
    color = color or {1, 1, 0}

    local recolor = self:addFX(RecolorFX())
    Game.battle.timer:during(8/30, function()
        recolor.color = Utils.lerp(recolor.color, color, 0.12 * DTMULT)
    end, function()
        Game.battle.timer:during(8/30, function()
            recolor.color = Utils.lerp(recolor.color, {1, 1, 1}, 0.16 * DTMULT)
        end, function()
            self:removeFX(recolor)
        end)
    end)
end

function EnemyBattler:getNameColors()
    local result = {}
    if self:canSpare() then
        table.insert(result, {1, 1, 0})
    end
    if self.tired then
        table.insert(result, {0, 0.7, 1})
    end
    return result
end

function EnemyBattler:getEncounterText()
    local has_spareable_text = self.spareable_text and self:canSpare()

    local priority_spareable_text = Game:getConfig("prioritySpareableText")
    if priority_spareable_text and has_spareable_text then
        return self.spareable_text
    end

    if self.low_health_text and self.health <= (self.max_health * self.low_health_percentage) then
        return self.low_health_text

    elseif self.tired_text and self.tired then
        return self.tired_text

    elseif has_spareable_text then
        return self.spareable_text
    end

    return Utils.pick(self.text)
end

function EnemyBattler:getTarget()
    return Game.battle:randomTarget()
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
        if type(self.check) == "table" then
            local tbl = {}
            for i,check in ipairs(self.check) do
                if i == 1 then
                    table.insert(tbl, "* " .. string.upper(self.name) .. " - " .. check)
                else
                    table.insert(tbl, "* " .. check)
                end
            end
            return tbl
        else
            return "* " .. string.upper(self.name) .. " - " .. self.check
        end
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

function EnemyBattler:hurt(amount, battler, on_defeat, color, show_status, attacked)
    if amount == 0 or (amount < 0 and Game:getConfig("damageUnderflowFix")) then
        if show_status ~= false then
            self:statusMessage("msg", "miss", color or (battler and {battler.chara:getDamageColor()}))
        end

        self:onDodge(battler, attacked)
        return
    end

    self.health = self.health - amount
    if show_status ~= false then
        self:statusMessage("damage", amount, color or (battler and {battler.chara:getDamageColor()}))
    end

    if amount > 0 then
        self.hurt_timer = 1
        self:onHurt(amount, battler)
    end

    self:checkHealth(on_defeat, amount, battler)
end

function EnemyBattler:checkHealth(on_defeat, amount, battler)
    -- on_defeat is optional
    if self.health <= 0 then
        self.health = 0

        if not self.defeated then
            if on_defeat then
                on_defeat(self, amount, battler)
            else
                self:forceDefeat(amount, battler)
            end
        end
    end
end

function EnemyBattler:forceDefeat(amount, battler)
    self:onDefeat(amount, battler)
end

function EnemyBattler:getAttackTension(points)
    -- In Deltarune, this is always 10*2.5, except for JEVIL where it's 15*2.5
    return points / 25
end

function EnemyBattler:getAttackDamage(damage, battler, points)
    if damage > 0 then
        return damage
    end
    return ((battler.chara:getStat("attack") * points) / 20) - (self.defense * 3)
end

function EnemyBattler:getDamageSound() end

function EnemyBattler:onHurt(damage, battler)
    self:toggleOverlay(true)
    if not self:getActiveSprite():setAnimation("hurt") then
        self:toggleOverlay(false)
    end
    self:getActiveSprite():shake(9, 0, 0.5, 2/30)

    if self.health <= (self.max_health * self.tired_percentage) then
        self:setTired(true)
    end
end

function EnemyBattler:onHurtEnd()
    self:getActiveSprite():stopShake()
    self:toggleOverlay(false)
end

function EnemyBattler:onDodge(battler, attacked) end

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

    Assets.playSound("defeatrun")

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

    Assets.playSound("deathnoise")

    local sprite = self:getActiveSprite()

    sprite.visible = false
    sprite:stopShake()

    local death_x, death_y = sprite:getRelativePos(0, 0, self)
    local death = FatalEffect(sprite:getTexture(), death_x, death_y, function() self:remove() end)
    death:setColor(sprite:getDrawColor())
    death:setScale(sprite:getScale())
    self:addChild(death)

    self:defeat("KILLED", true)
end

function EnemyBattler:heal(amount)
    Assets.stopAndPlaySound("power")
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

    Assets.playSound("petrify")

    self:toggleOverlay(true)

    local sprite = self:getActiveSprite()
    if not sprite:setAnimation("frozen") then
        sprite:setAnimation("hurt")
    end
    sprite:stopShake()

    self:recruitMessage("frozen")

    self.hurt_timer = -1

    sprite.frozen = true
    sprite.freeze_progress = 0

    Game.battle.timer:tween(20/30, sprite, {freeze_progress = 1})

    Game.battle.money = Game.battle.money + 24
    self:defeat("FROZEN", true)
end

function EnemyBattler:statusMessage(...)
    return super.statusMessage(self, self.width/2, self.height/2, ...)
end

function EnemyBattler:recruitMessage(...)
    return super.recruitMessage(self, self.width/2, self.height/2, ...)
end

function EnemyBattler:setRecruitStatus(v)
    Game:getRecruit(self.id):setRecruited(v)
end

function EnemyBattler:getRecruitStatus()
    return Game:getRecruit(self.id):getRecruited()
end

function EnemyBattler:isRecruitable()
    return Game:getRecruit(self.id)
end

function EnemyBattler:defeat(reason, violent)
    self.done_state = reason or "DEFEATED"

    if violent then
        Game.battle.used_violence = true
        if self:isRecruitable() and self:getRecruitStatus() ~= false then
            if Game:getConfig("enableRecruits") and self.done_state ~= "FROZEN" then
                self:recruitMessage("lost")
            end
            self:setRecruitStatus(false)
        end
        Game.battle.xp = Game.battle.xp + self.experience
    end
    
    if self:isRecruitable() and type(self:getRecruitStatus()) == "number" and (self.done_state == "PACIFIED" or self.done_state == "SPARED") then
        self:setRecruitStatus(self:getRecruitStatus() + 1)
        if Game:getConfig("enableRecruits") then
            local counter = self:recruitMessage("recruit")
            counter.first_number = self:getRecruitStatus()
            counter.second_number = Game:getRecruit(self.id):getRecruitAmount()
            Assets.playSound("sparkle_gem")
        end
        if self:getRecruitStatus() >= Game:getRecruit(self.id):getRecruitAmount() then
            self:setRecruitStatus(true)
        end
    end
    
    Game.battle.money = Game.battle.money + self.money

    Game.battle:removeEnemy(self, true)
end

function EnemyBattler:setActor(actor, use_overlay)
    super.setActor(self, actor, use_overlay)

    if self.sprite then
        self.sprite.facing = "left"
        self.sprite.inherit_color = true
    end
    if self.overlay_sprite then
        self.overlay_sprite.facing = "left"
        self.overlay_sprite.inherit_color = true
    end
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

    super.update(self)
end

function EnemyBattler:canDeepCopy()
    return false
end

function EnemyBattler:setFlag(flag, value)
    Game:setFlag("enemy#"..self.id..":"..flag, value)
end

function EnemyBattler:getFlag(flag, default)
    return Game:getFlag("enemy#"..self.id..":"..flag, default)
end

function EnemyBattler:addFlag(flag, amount)
    return Game:addFlag("enemy#"..self.id..":"..flag, amount)
end

return EnemyBattler