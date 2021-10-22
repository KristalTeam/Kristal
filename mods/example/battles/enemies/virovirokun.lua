local Virovirokun, super = Class(EnemyBattler)

function Virovirokun:init()
    super:init(self)
    self.name = "Virovirokun"

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.hp = 240
    self.attack = 8
    self.defense = 0
    self.reward = 84

    self.check = "This sick virus\nneeds affordable healthcare."

    self.text = {
        "* Virovirokun is sweating\nsuspiciously.",
        "* Virovirokun uses a text\ndocument as a tissue.",
        "* Virovirokun is poking round\nthings with a spear.",
        "* Virovirokun is beeping a\ncriminal tune."
    }

    self:registerAct("TakeCare")
    self:registerAct("TakeCareX", "", {"susie", "ralsei"})

end

function Virovirokun:onAct(battler, name)
    local kris_outfit = {"kris_virokun_nurse", "kris_virokun_doctor"}
    local sprite_lookup = {
        ["kris"] = kris_outfit[math.random(2)],
        ["susie"] = "susie_virokun",
        ["ralsei"] = "ralsei_virokun",
        ["noelle"] = "noelle_virokun"
    }
    local offset_lookup = {
        ["kris"]   = {4, 12 - 18 + 8},
        ["susie"]  = {6, 12 + 16 - 28},
        ["ralsei"] = {4 - 10, -12 + 13},
        ["noelle"] = {7, 0}
    }
    if name == "TakeCare" then
        local id = battler.info.id
        battler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
        self:addMercy(100)
        Game.battle:BattleText("* You treated Virovirokun with\ncare! It's no longer\ninfectious!")
        self:setText("Just what the\ndoctor ordered!")
    elseif name == "TakeCareX" then
        for _,ibattler in ipairs(Game.battle.party) do
            local id = ibattler.info.id
            ibattler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
        end
        for _,enemy in ipairs(Game.battle.enemies) do
            if enemy.id == "virovirokun" then
                enemy:addMercy(100)
                --enemy:setText("Just what the\ndoctor ordered!")
            else
                enemy:addMercy(50)
            end
        end
        Game.battle:BattleText("* Everyone treated the enemy with\ntender loving care!! All the\nenemies felt great!!")
    end
    super:onAct(self, battler, name)
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