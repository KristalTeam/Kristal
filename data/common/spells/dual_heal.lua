local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "dual_heal",
    -- Display name
    name = "Dual Heal",

    -- Battle description
    effect = "Heal All\n30 HP",
    -- Menu description
    description = "Heavenly light restores a little HP to\nall party members. Depends on Magic.",

    -- TP cost
    cost = 50,

    -- Target mode (party, enemy, or none/nil)
    target = "none",

    -- Tags that apply to this spell
    tags = {"heal"},
}

function spell:onCast(user, target)
    for _,battler in ipairs(Game.battle.party) do
        battler:heal(user.chara:getStat("magic") * 5.5)
    end
end

return spell