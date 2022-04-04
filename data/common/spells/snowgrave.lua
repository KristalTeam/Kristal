local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "snowgrave",
    -- Display name
    name = "SnowGrave",

    -- Battle description
    effect = "Fatal",
    -- Menu description
    description = "Deals the fatal damage to\nall of the enemies.",

    -- TP cost
    cost = 200,

    -- Target mode (party, enemy, or none/nil)
    target = nil,

    -- Tags that apply to this spell
    tags = {"ice", "fatal", "damage"},
}

function spell:onCast(user, target)
    local object = SnowGraveSpell(user)
    object.damage = math.ceil(((user.chara:getStat("magic") * 40) + 600))
    object.layer = BATTLE_LAYERS["above_ui"]
    Game.battle:addChild(object)

    return false
end

return spell