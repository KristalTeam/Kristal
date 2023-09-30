local spell, super = Class(Spell, "snowgrave")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "SnowGrave"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Fatal"
    -- Menu description
    self.description = "Deals the fatal damage to\nall of the enemies."

    -- TP cost
    self.cost = 200

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemies"

    -- Tags that apply to this spell
    self.tags = {"ice", "fatal", "damage"}
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)
    if chara and chara:checkWeapon("thornring") then
        cost = Utils.round(cost / 2)
    end
    return cost
end

function spell:onCast(user, target)
    local object = SnowGraveSpell(user)
    object.damage = self:getDamage(user, target)
    object.layer = BATTLE_LAYERS["above_ui"]
    Game.battle:addChild(object)

    return false
end

function spell:getDamage(user, target)
    return math.ceil((user.chara:getStat("magic") * 40) + 600)
end

return spell