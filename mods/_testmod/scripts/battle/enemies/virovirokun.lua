local Virovirokun, super = Class(EnemyBattler)

function Virovirokun:init()
    super:init(self)

    self.name = "Virovirokun"
    self:setActor("virovirokun")

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.max_health = 240
    self.health = 240
    self.attack = 8
    self.defense = 0
    self.gold = 84

    self.spare_points = 20

    self.waves = {
        "vironeedle"
        --"solidtest"
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
    self:registerAct("TakeCareX", "", "all")
    --self:registerAct("TakeCareX", "", {"kris", "susie", "ralsei"})
    --self:registerAct("TakeCareX", "", {"kris", "noelle"})
    self:registerShortAct("Quarantine", "Make\nenemy\nTIRED", {"kris"})
    self:registerActFor("kris", "R-Cook", "", {"ralsei"})
    self:registerActFor("kris", "S-Cook", "", {"susie"})
    self:registerActFor("ralsei", "Cook")
    self:registerActFor("susie", "Cook")

    self.text_override = nil
end

function Virovirokun:isXActionShort(battler)
    return true
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
        local id = battler.chara.id
        battler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
    elseif name == "TakeCareX" then
        for _,ibattler in ipairs(Game.battle.party) do
            local id = ibattler.chara.id
            ibattler:setActSprite(sprite_lookup[id], offset_lookup[id][1], offset_lookup[id][2])
        end
    else
        super:onActStart(self, battler, name)
    end
end

function Virovirokun:onShortAct(battler, name)
    if name == "Quarantine" then
        print("telling virovirokun to stay home, naughty naughty")
        if battler.chara.id == "kris" then
            return "* You told Virovirokun to stay home."
        else
            return "* " .. battler.chara.name .. " told Virovirokun to stay home."
        end
    elseif name == "Standard" then
        self:addMercy(50)
        if battler.chara.id == "noelle" then
            return "* Noelle offered a cold compress!"
        elseif battler.chara.id == "susie" then
            return "* Susie encouraged evil!"
        elseif battler.chara.id == "ralsei" then
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
        self:setTired(true)
        self.text_override = "Fine..."
        return "* You told Virovirokun to stay home.\nVirovirokun became [color:blue]TIRED[color:reset]..."

        --local heck = DamageNumber("damage", love.math.random(600), 200, 200, battler.actor.dmg_color)
        --self.parent:addChild(heck)
    elseif name == "TakeCareX" then
        for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
            if enemy.id == "virovirokun" then
                enemy:addMercy(100)
            else
                enemy:addMercy(50)
            end
        end
        return "* Everyone treated the enemy with\ntender loving care!! All the\nenemies felt great!!"
    elseif name == "R-Cook" then
        Game.battle:startActCutscene("virovirokun", "cook_ralsei")
        return
    elseif name == "S-Cook" then
        Game.battle:startActCutscene("virovirokun", "cook_susie")
        return
    elseif name == "Cook" then
        if battler.chara.id == "ralsei" then
            Game.battle:startActCutscene("virovirokun", "cook_ralsei")
        elseif battler.chara.id == "susie" then
            Game.battle:startActCutscene("virovirokun", "cook_susie")
        else
            self:addMercy(20)
            return "* "..battler.chara.name.." cooked up a cure!"
        end
        return
    elseif name == "Standard" then
        self:addMercy(50)
        if battler.chara.id == "noelle" then
            return "* Noelle offered a cold compress!"
        elseif battler.chara.id == "susie" then
            Game.battle:startActCutscene(function(cutscene)
                cutscene:text("* Susie commiserated with the enemy!")
                cutscene:text("* Stick it to the man,\ndude.", "smile", "susie")
                cutscene:text("* Even if that means\ncloning yourself, or\nwhatever.", "smile", "susie")
            end)
            return
        elseif battler.chara.id == "ralsei" then
            Game.battle:startActCutscene(function(cutscene)
                cutscene:text("* Ralsei tried to steer the enemy\ndown the right path.")
                cutscene:text("* Not everybody knows\nthis, but...", "smile", "ralsei")
                cutscene:text("* Crimes are bad. ... Did\nyou know that?",  "blush_smile", "ralsei")
            end)
            return
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