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

    self.waves = {}

    self.check = "Remember to change\nyour check text!"

    self.text = {
        "* Test Enemy is testing."
    }

    self.low_health_text = "* Enemy is feeling tired."

    self.acts = {
        {
            ["name"] = "Check",
            ["description"] = "",
            ["party"] = {}
        }
    }

    self.flash_siner = 0
    self.hurt_timer = 0
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
function EnemyBattler:spare(...)    print("TODO: implement!") end -- TODO

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

        local src = love.audio.newSource("assets/sounds/snd_mercyadd.wav", "static")
        src:setVolume(0.8)
        src:setPitch(pitch)
        src:play()
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
    return self.text[math.random(#self.text)]
end

function EnemyBattler:selectWave()
    return self.waves[love.math.random(#self.waves)]
end

function EnemyBattler:onCheck(battler) end

function EnemyBattler:onActStart(battler, name)
    battler:setAnimation("battle/act")
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
    love.audio.newSource("assets/sounds/snd_damage.wav", "static"):play()

    self.health = self.health - amount
    self:statusMessage("damage", amount, battler and battler.chara.dmg_color)

    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("hurt")

    self.overlay_sprite.shake_x = 9
    self.hurt_timer = 1
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

function EnemyBattler:preDraw()
    super:preDraw(self)
    if Game.battle:isEnemySelected(self) then
        self.flash_siner = self.flash_siner + DTMULT
        love.graphics.setShader(Kristal.Shaders["White"])
        Kristal.Shaders["White"]:send("whiteAmount", -math.cos(self.flash_siner / 5) * 0.4 + 0.6)
    else
        self.flash_siner = 0
    end
end

function EnemyBattler:postDraw()
    if Game.battle:isEnemySelected(self) then
        love.graphics.setShader()
    end
    super:postDraw(self)
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

    super:update(self, dt)
end

return EnemyBattler