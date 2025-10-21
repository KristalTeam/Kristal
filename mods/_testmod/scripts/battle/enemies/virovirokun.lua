local Virovirokun, super = Class("virovirokun", true)

function Virovirokun:init()
    super.init(self)

    if Game:getPartyMember("susie"):getFlag("auto_attack") then
        self:registerAct("Warning")
    end

    self.susie_warned = false

    self.asleep = false
    self.become_red = false

    self.nb_checks = 0

    self:registerAct("Tell Story", "", {"ralsei"})
    self:registerAct("Red", "", {"susie"})
    self:registerAct("", "", nil, nil, nil, {"ui/battle/msg/dumbass"})

    local description = "Red\ndamage"
    if Game.chapter <= 3 then
        description = "Red\nDamage"
    end

    if Game:getFlag("insomniac_virovirokun") then
        self:setTired(true)
    end

    self:registerAct("Red Buster", description, "susie", 60)
    self:registerAct("DualHeal", "Heals\neveryone", "ralsei", 50)

    self:registerAct("LoudTired", "TIRED\nmessage...", nil, 0)
    self:registerAct("QuietTired", "No TIRED\nmessage...", nil, -100)
    self:registerAct("Nether", "Oops! No\nsleep")
end

function Virovirokun:getSpareText(battler, success)
    local result = super.getSpareText(self, battler, success)
    if not success then
        if type(result) ~= "table" then
            result = {result}
        end
        result[1] = "* " .. battler.chara:getName() .. " spared " .. self.name .. "!\n* But its name wasn't [color:green]GREEN[color:reset]..."
    end
    return result
end

function Virovirokun:onCheck()
    self.nb_checks = self.nb_checks + 1
end

function Virovirokun:getCheckText(battler)
    local text = super.getCheckText(self, battler)
    if type(text) ~= "table" then
        text = {text}
    end

    if #Game.battle:getActiveEnemies() > 100 then
        return "* A LOT OF ENEMIES. YOU'RE GONNA DIE."
    end

    if self.nb_checks > 1 then
        table.insert(text, "* "..battler.chara:getName().." can't get more info on the enemy!")
    end

    if self.nb_checks == 3 and #Game.battle.party >= 2 then
        table.insert(text, "* "..Game.battle.party[2].chara:getName().." tells you to stop checking.")
    elseif self.nb_checks == 4 and #Game.battle.party >= 3 then
        table.insert(text, "* "..Game.battle.party[3].chara:getName().." begs you to stop checking!")
    elseif self.nb_checks > 4 and self.nb_checks < 9 then
        table.insert(text, "* What are you even doing?")
    elseif self.nb_checks == 9 then
        table.insert(text, "* [color:red]You feel like checking further is a bad idea[color:reset]...")
    elseif self.nb_checks == 10 then
        battler:hurt(999, nil, nil, {swoon=true})
        return "* Ok you're getting annoying."
    end
    return text
end

function Virovirokun:mercyFlash(color)
    super.mercyFlash(self, color or {0, 1, 0})
end

function Virovirokun:getNameColors()
    local result = {}
    if self.become_red then
        table.insert(result, {1, 0, 0})
    end
    if self:canSpare() then
        table.insert(result, {0, 1, 0})
    end
    if self.tired then
        table.insert(result, {0, 0.7, 1})
    end
    return result
end

function Virovirokun:onAct(battler, name)
    self.acted_once = true
    if name == "DualHeal" then
        Game.battle:powerAct("dual_heal", battler, "ralsei")
    elseif name == "Red Buster" then
        Game.battle:powerAct("red_buster", battler, "susie", self)
    elseif name == "Warning" then
        self.susie_warned = true
        self.comment = "(Warned)"
        return "* You told Virovirokun to watch out for Susie's attacks.[wait:5]\n* It went on guard."
    elseif name == "Tell Story" then
        for _,v in ipairs(Game.battle.enemies) do
            v.asleep = true
            v:setTired(true)
            v.comment = "(Sleepy)"
            v:setScale(4, 2)
            v.text_override = "Zzz..."
        end
        self:addMercy(100)
        local susie = Game.battle:getPartyBattler("susie")
        if susie then
            susie:setSleeping(true)
        end
        return "* Ralsei tells Virovirokun a story.[wait:5]\n* The enemies fell asleep![wait:5]\n* Susie fell asleep too!"
    elseif name == "Red" then
        self.become_red = true
        self:setColor(1, 0, 0)
        return "* You and Susie turned Virovirokun red."
    elseif name == "" then
        battler:hurt(math.huge)
        return "* Dumbass"
    elseif name == "LoudTired" then
        local text = {"* You made Virovirokun TIRED by blasting nightcore remixes out at full volume!"}
        Game.battle.music:setPitch(1.25)
        Game.battle.music:setVolume(1)

        if Game.chapter < 3 then
            table.insert(text, "[sound:awkward]* But you were still in Chapter 2...")
            self.text_override = "Happy New Year 2025!"
        end

        self:setTired(true)
        return text
    elseif name == "QuietTired" then
        local text = {"* You made Virovirokun TIRED with the sound of deafening silence."}
        Game.battle.music:pause()

        if Game.chapter < 3 then
            table.insert(text, "[sound:awkward]* But you were still in Chapter 2...")
        end

        self:setTired(true, true)
        return text
    elseif name == "Nether" then
        -- I would never: steal code from Acts three branches above this one
        self.become_red = true
        self:setColor(1, 0, 0)
        self.tired_percentage = 0
        self:setTired(false)

        return "* You sent Virovirokun to the Nether.[wait:5]\n* Its sleep quality diminished immensely!"
    else
        return super.onAct(self, battler, name)
    end
end

function Virovirokun:getAttackDamage(damage, battler, points)
    if self.susie_warned and battler.chara.id == "susie" then
        return 0
    else
        return super.getAttackDamage(self, damage, battler, points)
    end
end

function Virovirokun:getNextWaves()
    if self.asleep then
        return nil
    end
    return super.getNextWaves(self)
end

function Virovirokun:onTurnEnd()
    if Game:getFlag("insomniac_virovirokun") then
        self:setTired(false)
        self:setTired(true)
    end
end

return Virovirokun
