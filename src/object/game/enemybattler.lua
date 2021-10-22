local EnemyBattler, super = Class(Object)

function EnemyBattler:init(chara)
    super:init(self)
    self.name = "Test Enemy"

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.layer = -10

    if chara then
        self:setCharacter(chara)
    end

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.hp = 0
    self.attack = 0
    self.defense = 0
    self.reward = 0

    self.tired = false
    self.mercy = 0

    self.check = "Remember to change\nyour check text!"

    self.text = {
        "* Test Enemy is testing."
    }

    self.acts = {
        {
            ["name"] = "Check",
            ["description"] = "",
            ["party"] = {}
        }
    }

    self.flash_siner = 0
end
function EnemyBattler:registerAct(name, description, party)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party
    }
    table.insert(self.acts, act)
end

function EnemyBattler:setText(...)  print("TODO: implement!") end -- TODO
function EnemyBattler:spare(...)    print("TODO: implement!") end -- TODO

function EnemyBattler:onSpareable()
    self:setBattleSprite("spared", 1/15, false)
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

function EnemyBattler:onCheck(battler) end

function EnemyBattler:onAct(battler, name)
    if name == "Check" then
        self:onCheck(battler)
        Game.battle:BattleText("* " .. self.name .. " - " .. self.check)
    end
end

function EnemyBattler:getXAction(battler)
    return "Standard"
end

function EnemyBattler:onXAction(battler, name) end

function EnemyBattler:statusMessage(type, arg)
    local hit_count = Game.battle.hit_count
    hit_count[self] = hit_count[self] or 0

    local x, y = self:getRelativePos(self.parent, 0, self.height/2)

    local percent = DamageNumber(type, arg, x, y + 20 - (hit_count[self] * 20))
    self.parent:addChild(percent)

    hit_count[self] = hit_count[self] + 1
end

function EnemyBattler:setCharacter(id)
    self.data = Registry.getCharacter(id)

    self.width = self.data.width
    self.height = self.data.height

    if self.sprite then
        self:removeChild(self.sprite)
    end

    self.sprite = CharacterSprite(self.data)
    self:addChild(self.sprite)

    self.sprite:play(1/5, true)
end

function EnemyBattler:preDraw()
    super:preDraw(self)
    if Game.battle.state == "ENEMYSELECT" and Game.battle.enemies[Game.battle.current_menu_y] == self then
        self.flash_siner = self.flash_siner + DTMULT
        love.graphics.setShader(Kristal.Shaders["White"])
        Kristal.Shaders["White"]:send("whiteAmount", -math.cos(self.flash_siner / 5) * 0.4 + 0.6)
    else
        self.flash_siner = 0
    end
end

function EnemyBattler:postDraw()
    if Game.battle.state == "ENEMYSELECT" and Game.battle.enemies[Game.battle.current_menu_y] == self then
        love.graphics.setShader()
    end
    super:postDraw(self)
end

function EnemyBattler:setBattleSprite(sprite, speed, loop, after)
    if self.data and self.data.battle and self.data.battle[sprite] then
        self:setSprite(self.data.battle[sprite], speed, loop, after)
        return true
    end
    return false
end

function EnemyBattler:setSprite(sprite, speed, loop, after)
    if not self.sprite then
        self.sprite = Sprite(sprite)
        self:addChild(self.sprite)
    else
        self.sprite:setSprite(sprite)
    end
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop, false, after)
    end
end

function EnemyBattler:setCustomSprite(sprite, ox, oy, speed, loop, after)
    self.sprite:setCustomSprite(sprite, ox, oy)
    if not self.sprite.directional then
        self.sprite:play(speed or (1/15), loop, false, after)
    end
end

return EnemyBattler