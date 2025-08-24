local Starwalker, super = Class(EnemyBattler)

function Starwalker:init()
    super.init(self)

    self.name = "Starwalker"
    self:setActor("starwalker")

    self.path = "enemies/starwalker"
    self.default = ""
    self.sprite:set("wings")

    self.max_health = 2400
    self.health = 2400
    self.attack = 1
    self.defense = 0
    self.money = 123456

    self.spare_points = 0

    self.exit_on_defeat = true

    self.text = {
        "* Star walker",
        "* Smells like the original    [wait:5][color:yellow]Starwalker[color:reset]",
        "* The air crackles with [color:yellow]star walker[color:reset].",
        "* this [color:yellow]battle[color:reset] is     [color:yellow]pissing[color:reset] me\noff..."
    }

    self.low_health_text = "* Star walker is [color:yellow]Pissed[color:reset] off..."

    self:registerAct("Star walker", "")

    local description = "Red\ndamage"
    if Game.chapter <= 3 then
        description = "Red\nDamage"
    end

    self:registerAct("Red Buster", description, "susie", 60)
    self:registerAct("DualHeal", "Heals\neveryone", "ralsei", 50)

    self.text_override = nil

    self.old_x = self.x
    self.old_y = self.y

    self.mode = "normal"
    self.ease = false

    self.ease_timer = 0

    self.timer = 0

    self.progress = 0

    self.waves = {
        "starwalker/starwingsfaster"
    }

    self.blue = false

    self:setTired(true)
    self:setTired(false)

    self.was_hit = false
end

function Starwalker:makeBullet(x, y)
    if (Utils.random() < 0.25) then
        return Registry.createBullet("FallenStarBullet", x, y)
    end

    return Registry.createBullet("StarBullet", x, y)
end

function Starwalker:onAct(battler, name)
    if name == "Check" then
        self:onCheck(battler)

        local check_text = {
            "* Starwalker - AT 1 DF 1\n[wait:5]* The   [color:yellow]original[color:reset]  enemy\n[wait:5]* Can only deal [sound:vine_boom][offset:0,-16][font:main_mono,64]1[offset:0,16][font:reset][wait:10] damage"
        }

        if (self.was_hit) then
            table.insert(check_text, "* Can't keep dodging forever.[wait:5]\n* Keep attacking.")
        end

        return check_text
    elseif name == "DualHeal" then
        Game.battle:powerAct("dual_heal", battler, "ralsei")
    elseif name == "Red Buster" then
        Game.battle:powerAct("red_buster", battler, "susie", self)
    elseif name == "Star walker" then
        self:addMercy(0.01)
        return "* The Original Starwalker  absorbs the\nACT"
    elseif name == "Standard" then
        self:addMercy(0.01)
        if battler.chara.id == "ralsei" then
            return "* Ralsei passes away\n(it got [color:yellow]absorbed)"
        elseif battler.chara.id == "susie" then
            return "* Susie more like sussy\n(it got [color:yellow]absorbed)"
        end
    end

    return super.onAct(self, battler, name)
end

function Starwalker:onHurt(damage, battler)
    super.onHurt(self, damage, battler)

    -- This doesn't get called if damage is 0 but we'll check anyway
    if damage > 0 then
        self.was_hit = true
    end
end

function Starwalker:getGrazeTension()
    return 0
end

function Starwalker:onTurnEnd()
    self.progress = self.progress + 1
end

function Starwalker:getEncounterText()
    if (self.progress == 2) then
        return "* Star walker is preparing\n[color:blue]something [offset:0,-8][color:red][font:main_mono,48]!!"
    end
    return super.getEncounterText(self)
end

function Starwalker:getNextWaves()
    self.blue = false

    --[[if true then
        self.blue = true
        return {"starwalker/starup"}
    end]]

    if (self.progress == 0) then
        return { "starwalker/starwings" }
    elseif (self.progress == 1) then
        return { "starwalker/starwingsfaster" }
    elseif (self.progress == 2) then
        return { "starwalker/staract" }
    elseif (self.progress == 3) then
        self.blue = true
        return { "starwalker/starwings" }
    elseif (self.progress == 4) then
        self.blue = true
        return { "starwalker/starwingsfaster" }
    elseif (self.progress == 5) then
        self.blue = true
        return { "starwalker/starup" }
    end

    return super.getNextWaves(self)
end

function Starwalker:setMode(mode)
    self.mode = mode
    self.old_x = self.x
    self.old_y = self.y
    self.ease = true
    self.ease_timer = 0
end


function Starwalker:update()
    super.update(self)

    if not self.done_state and (Game.battle:getState() ~= "TRANSITION") then
        self.timer = self.timer + (1 * DTMULT)

        local wanted_x = self.old_x
        local wanted_y = self.old_y

        if self.mode == "normal" then
            wanted_x = 530 + (math.sin(self.timer * 0.08) * 20)
            wanted_y = 238 + (math.sin(self.timer * 0.04) * 10)
        elseif self.mode == "shoot" then
            wanted_x = 530 - 40 + (math.sin(self.timer * 0.08) * 10)
            wanted_y = 238 - 50 + (math.sin(self.timer * 0.04) * 40)
        elseif self.mode == "still" then
            wanted_x = 530 - 40
            wanted_y = 238 - 50
        end

        if not self.ease then
            self.x = wanted_x
            self.y = wanted_y
        else
            self.ease_timer = self.ease_timer + (0.05 * DTMULT)
            self.x = Ease.outQuad(self.ease_timer, self.old_x, wanted_x - self.old_x, 1)
            self.y = Ease.outQuad(self.ease_timer, self.old_y, wanted_y - self.old_y, 1)
            if self.ease_timer >= 1 then
                self.ease = false
            end
        end
    end

    for _,enemy in pairs(Game.battle.enemy_world_characters) do
        enemy:remove()
    end
end

function Starwalker:onSpared()
    super.onSpared(self)

    self.sprite:resetSprite()
    Game.battle.music:stop()
end

function Starwalker:isXActionShort(battler)
    return true
end

function Starwalker:onActStart(battler, name)
    super.onActStart(self, battler, name)
end

function Starwalker:onShortAct(battler, name)
    if name == "Standard" then
        self:addMercy(0.1)
        if battler.chara.id == "ralsei" then
            return "* Ralsei passes away"
        elseif battler.chara.id == "susie" then
            return "* Susie more like sussy"
        end
    end
    return nil
end


function Starwalker:getEnemyDialogue()
    if self.text_override then
        local dialogue = self.text_override
        self.text_override = nil
        return dialogue
    end

    local dialogue
    if self.mercy >= 100 then
        dialogue = {
            "Aough",
            "You wi"
        }
    else
        dialogue = {
            "star",
            "walkin",
            "stark",
            "warper",
            "starwalker",
            "[style:dark_menu][color:yellow]Pissing",
            "me off",
        }
    end
    return dialogue[math.random(#dialogue)]
end

return Starwalker
