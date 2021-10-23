return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "ralsei",
    -- Display name
    name = "Ralsei",
    -- Character data
    chara = Registry.getActor("ralsei"),

    -- Head icon in the equip / power menu
    head_icon = "party/ralsei/menu/dark",
    -- Title / class (saved to the save file)
    title = "LV1 Dark Prince\nDark-World being.\nHas friends now.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- Spells by id
    spells = {"pacify", "heal_prayer"},

    -- Current health (saved to the save file)
    health = 100,

    -- Base stats (saved to the save file)
    stats = {
        health = 100,
        attack = 10,
        defense = 2,
        magic = 9
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/scarf",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "red_scarf",
        armor = {}
    },
}