local Virovirokun, super = Class(EnemyBattler)

function Virovirokun:init()
    super:init(self)

    self.name = "Virovirokun"
    self:setCharacter("virovirokun")

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.max_health = 240
    self.health = 240
    self.attack = 8
    self.defense = 0
    self.reward = 84

    self.waves = {
        "vironeedle"
    }

    self.check = "This sick virus\nneeds affordable healthcare."

    self.text = {
        "* Virovirokun is sweating\nsuspiciously.",
        "* Virovirokun uses a text\ndocument as a tissue.",
        "* Virovirokun is poking round\nthings with a spear.",
        "* Virovirokun is beeping a\ncriminal tune."
    }

    self.low_health_text = "* Virovirokun looks extra sick."

    self:registerAct("TakeCare")
    self:registerAct("TakeCareX", "", {"susie", "ralsei"})
    self:registerAct("TakeCareX", "", {"noelle"})
    self:registerShortAct("Quarantine", "Make\nenemy\nTIRED")

    self.text_override = nil
end

function Virovirokun:onActStart(battler, name)
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
        local id = battler.actor.id
        battler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
    elseif name == "TakeCareX" then
        for _,ibattler in ipairs(Game.battle.party) do
            local id = ibattler.actor.id
            ibattler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
        end
    else
        battler:setAnimation("battle/act")
    end
end

function Virovirokun:onShortAct(battler, name)
    if name == "Quarantine" then
        print("telling virovirokun to stay home, naughty naughty")
        if battler.id == "kris" then
            return "* You told Virovirokun to stay home."
        else
            return "* " .. battler.chara.name .. " told Virovirokun to stay home."
        end
    elseif name == "Standard" then
        self:addMercy(50)
        if battler.id == "noelle" then
            return "* Noelle offered a cold compress!"
        elseif battler.id == "susie" then
            return "* Susie encouraged evil!"
        elseif battler.id == "ralsei" then
            return "* Ralsei tried to rehabilitate!"
        end
    end
    return nil
end


function Virovirokun:onAct(battler, name)
    if name == "TakeCare" then
        self:addMercy(100)
        return "* You treated Virovirokun with\ncare! It's no longer\ninfectious!"
    elseif name == "Quarantine" then
        self.tired = true
        self.text_override = "Fine..."
        return "* You told Virovirokun to stay home.\nVirovirokun became [color:blue]TIRED[color:reset]..."

        --local heck = DamageNumber("damage", love.math.random(600), 200, 200, battler.actor.dmg_color)
        --self.parent:addChild(heck)
    elseif name == "TakeCareX" then
        for _,enemy in ipairs(Game.battle.enemies) do
            if enemy.id == "virovirokun" then
                enemy:addMercy(100)
            else
                enemy:addMercy(50)
            end
        end
        return "* Everyone treated the enemy with\ntender loving care!! All the\nenemies felt great!!"
    elseif name == "Standard" then
        self:addMercy(50)
        if battler.id == "noelle" then
            return "* Noelle offered a cold compress!"
        elseif battler.id == "susie" then
            return {
                "* Susie commiserated with the enemy!",
                "* Stick it to the man,\ndude.",
                "* Even if that means\ncloning yourself, or\nwhatever."
            }
        elseif battler.id == "ralsei" then
            return {
                "* Ralsei tried to steer the enemy\ndown the right path.",
                "* Not everybody knows\nthis, but...",
                "* Crimes are bad. ... Did\nyou know that?"
            }
        end
    end
    return super:onAct(self, battler, name)
end

function Virovirokun:getEnemyDialogue()
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
            "Don't let\nthis bug ya!",
            "Happy new\nyear 1997!",
            "I've got a love\nletter for you.",
            "I'm the fever,\nI'm the chill."
        }
    end
    return dialogue[math.random(#dialogue)]
end

return Virovirokun