return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "susie",
    -- Display name
    name = "Susie",
    -- Character data
    chara = Registry.getActor("susie"),

    -- Head icon in the equip / power menu
    head_icon = "party/susie/menu/dark",
    -- Title / class (saved to the save file)
    title = "LV1 Dark Knight\nDoes damage using\ndark energy.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- Spells by id
    spells = {"rude_buster", "ultimate_heal"},

    -- Current health (saved to the save file)
    health = 140,

    -- Base stats (saved to the save file)
    stats = {
        health = 140,
        attack = 14,
        defense = 2,
        magic = 1
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/axe",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "mane_ax",
        armor = {}
    },
}