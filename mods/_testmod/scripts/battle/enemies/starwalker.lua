local Starwalker, super = Class(EnemyBattler)

function Starwalker:init()
    super:init(self)

    self.name = "Starwalker"
    self:setActor("starwalker")

    self.path = "enemies/starwalker"
    self.default = ""
    self.sprite:set("wings")

    self.max_health = 2400
    self.health = 2400
    self.attack = 8
    self.defense = 0
    self.money = 123456

    self.spare_points = 0

    self.exit_on_defeat = true
    self.auto_spare = true

    self.waves = {
        "starwings"
        --"solidtest"
    }

    self.check = "The   original\n            ."

    self.text = {
        "* Star walker",
        "* Smells like   [color:yellow]pissed off[color:reset]",
        "*               this encounter\n is against star  walker",
        "* this [color:yellow]battle[color:reset] is     [color:yellow]pissing[color:reset] me\noff..."
    }

    self.low_health_text = "* Star walker has      hurt"

    self:registerAct("Star walker", "")
    self:registerAct("Red Buster", "Red\nDamage", "susie", 60)
    self:registerAct("DualHeal", "Heals\neveryone", "ralsei", 50)

    self.text_override = nil
end

function Starwalker:onSpared()
    super:onSpared(self)

    self.sprite:resetSprite()
    Game.battle.music:stop()
end

function Starwalker:isXActionShort(battler)
    return true
end

function Starwalker:onActStart(battler, name)
    super:onActStart(self, battler, name)
end

function Starwalker:onAct(battler, name)
    if name == "DualHeal" then
        Game.battle:powerAct("dual_heal", battler, "ralsei")
    elseif name == "Red Buster" then
        Game.battle:powerAct("red_buster", battler, "susie", self)
    elseif name == "Star walker" then
        self:addMercy(8)
        return "* The Original Starwalker  absorbs the\nACT"
    elseif name == "Standard" then
        self:addMercy(4)
        if battler.chara.id == "ralsei" then
            return "* Ralsei passes away\n(it got [color:yellow]absorbed)"
        elseif battler.chara.id == "susie" then
            return "* Susie more like sussy\n(it got [color:yellow]absorbed)"
        end
    end
    return super:onAct(self, battler, name)
end

function Starwalker:onShortAct(battler, name)
    if name == "Standard" then
        self:addMercy(4)
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
            "Just what the\ndoctor ordered!",
            "Kindness is\ncontagious!"
        }
    else
        dialogue = {
            "star"
        }
    end
    return dialogue[math.random(#dialogue)]
end

return Starwalker