local Virovirokun, super = Class(EnemyBattler)

function Virovirokun:init()
    self.name = "Virovirokun"
    self.id = "virovirokun"

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.hp = 240
    self.attack = 8
    self.defense = 0
    self.reward = 84

    self.check = "This sick virus\nneeds affordable healthcare."

    self.text = {
        "* Virovirokun is sweating suspiciously.",
        "* Virovirokun uses a text document as a tissue.",
        "* Virovirokun is poking round things with a spear.",
        "* Virovirokun is beeping a\ncriminal tune."
    }

    self:registerAct("TakeCareX", "", {"susie", "ralsei"})

end

function Virovirokun:onAct(name)
    if name == "TakeCare" then
        self:addMercy(100)
        Game.battle:BattleText("* You treated Virovirokun with\ncare! It's no longer\ninfectious!")
        self:setText("Just what the\ndoctor ordered!")
    elseif name == "TakeCareX" then
        for _,enemy in ipairs(Game.battle.enemies) do
            if enemy.id == "virovirokun" then
                enemy:addMercy(100)
                enemy:setText("Just what the\ndoctor ordered!")
            else
                enemy:addMercy(50)
            end
        end
        Game.battle:BattleText("* Everyone treated the enemy with\ntender loving care!! All the\nenemies felt great!!")
    end
end

function Virovirokun:onXAction(battler, name)
    -- for Virovirokun, name will always be Standard
    self:addMercy(50)
    if battler.id == "noelle" then
        return "* Noelle offered a cold compress!"
    elseif battler.id == "susie" then
        return "* Susie encouraged evil!"
    elseif battler.id == "ralsei" then
        return "* Ralsei tried to rehabilitate!"
    end
end

return Virovirokun