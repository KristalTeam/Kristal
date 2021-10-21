local EnemyBattler = Class()

function EnemyBattler:init()
    self.name = "Test Enemy"
    self.id = "test_enemy" -- Optional, defaults to file name

    self.path = "enemies/virovirokun"
    self.default = "idle"

    self.hp = 0
    self.attack = 0
    self.defense = 0
    self.reward = 0

    self.tired = false
    self.can_spare = false

    self.check = "Remember to change\nyour check text!"

    self.text = {
        "* Test Enemy is testing."
    }

    self:registerAct("TakeCareX", "", {"susie", "ralsei"})
end

function EnemyBattler:registerAct(...) print("TODO: implement!") end -- TODO
function EnemyBattler:addMercy(...)    print("TODO: implement!") end -- TODO
function EnemyBattler:setText(...)     print("TODO: implement!") end -- TODO

function EnemyBattler:onCheck(battler) end

function EnemyBattler:onAct(name) end

function EnemyBattler:getXAction(battler)
    return "Standard"
end

function EnemyBattler:onXAction(battler, name) end

return EnemyBattler