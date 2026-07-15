-- 
local spell, super = Class(Spell, "heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Heal"
    -- Name displayed when cast (optional)
    self.cast_name = "OKHEAL"

    -- Battle description
    self.effect = "Can't\nuse"
    -- Menu description
    self.description = "It seems the user doesn't\nwant to use this spell."

    -- TP cost
    self.cost = 102

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = { "heal" }
end

function spell:getPowerMenuTPDisplay(chara)
    if Game.battle == nil then
        return "??%"
    end

    return super.getPowerMenuTPDisplay(self, chara)
end


function spell:onCast(user, target)
    local healing_used = user.chara:getFlag("healing_used", 0)

    if healing_used < 15 then
        healing_used = healing_used + 1
        user.chara:setFlag("healing_used", healing_used)
    end

    local base_heal = math.ceil((user.chara:getStat("magic") * 5) + 15 + healing_used)
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara, target.chara)

    target:heal(heal_amount)
end

return spell
