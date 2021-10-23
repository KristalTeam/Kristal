return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "kris",
    -- Display name
    name = "Kris",
    -- Character data
    chara = Registry.getActor("kris"),

    -- Head icon in the equip / power menu
    head_icon = "party/kris/menu/dark",
    -- Title / class (saved to the save file)
    title = "LV1 Leader\nCommands the party\nwith various ACTs.",

    -- Whether the party member can act / use spells
    has_act = true,
    has_spells = false,

    -- Spells by id
    spells = {},

    -- Current health (saved to the save file)
    health = 120,

    -- Base stats (saved to the save file)
    stats = {
        health = 120,
        attack = 10,
        defense = 2,
        magic = 0
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/sword",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "wood_blade",
        armor = {}
    },
}