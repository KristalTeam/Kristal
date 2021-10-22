local EnemyBattler, super = Class(Object)

function EnemyBattler:init()
    super:init(self)
    self.name = "Test Enemy"
    self.id = "test_enemy" -- Optional, defaults to file name

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.layer = -10

    --self.sprite = Sprite()

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

end
function EnemyBattler:registerAct(name, description, party)
    local act = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party
    }
    table.insert(self.acts, act)
end

function EnemyBattler:addMercy(...) print("TODO: implement!") end -- TODO
function EnemyBattler:setText(...)  print("TODO: implement!") end -- TODO
function EnemyBattler:spare(...)    print("TODO: implement!") end -- TODO

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

return EnemyBattler