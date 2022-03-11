local item = HealItem{
    -- Item ID (optional, defaults to path)
    id = "cd_bagel",
    -- Display name
    name = "CD Bagel",

    -- Item type (item, key, weapon, armor)
    type = "item",
    -- Item icon (for equipment)
    icon = nil,

    -- Battle description
    effect = "Heals\n80HP",
    -- Shop description
    shop = "Musical food\nwith a\ncrunch.\nHeals 80HP",
    -- Menu description
    description = "A bagel with a reflective inside.\nMakes music with each bite. +80HP",

    -- Amount healed (HealItem variable)
    heal_amount = 80,

    -- Shop sell price
    price = 50,

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    target = "party",
    -- Where this item can be used (world, battle, all, or none/nil)
    usable_in = "all",
    -- Item this item will get turned into when consumed
    result_item = nil,
    -- Will this item be instantly consumed in battles?
    instant = false,

    -- Equip bonuses (for weapons and armor)
    bonuses = {},
    -- Bonus name and icon (displayed in equip menu)
    bonus_name = nil,
    bonus_icon = nil,

    -- Equippable characters (default true for armors, false for weapons)
    can_equip = {},

    -- Character reactions (key = party member id)
    reactions = {
        susie = "It's got crunch",
        ralsei = "How elegant!",
        noelle = "What a nice song..."
    },
    -- Sound effect that is played when a bagel is consumed in the overworld.
    bagel_sfx = {
        ["kris"] = "snd_cd_bagel_kris",
        ["susie"] = "snd_cd_bagel_susie",
        ["ralsei"] = "snd_cd_bagel_ralsei",
        ["noelle"] = "snd_cd_bagel_noelle",
    }

}

function item:onWorldUse(target)
    if Assets.getSound(item.bagel_sfx[target.id]) then
        Assets.playSound(item.bagel_sfx[target.id])
    end
    Game.world:heal(target, item.heal_amount)
    return true
end

return item