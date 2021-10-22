return PartyMember{
    -- Party member ID (optional, defaults to path)
    id = "noelle",
    -- Display name
    name = "Noelle",
    -- Character data
    chara = Registry.getCharacter("noelle"),

    -- Head icon in the equip / power menu
    head_icon = "party/noelle/menu/dark",
    -- Title / class (saved to the save file)
    title = "LV1 Snowcaster\nMight be able to\nuse some cool moves.",

    -- Whether the party member can act / use spells
    has_act = false,
    has_spells = true,

    -- Spells by id
    spells = {"heal_prayer", "sleep_mist", "ice_shock"},

    -- Current health (saved to the save file)
    health = 90,

    -- Base stats (saved to the save file)
    stats = {
        health = 90,
        attack = 3,
        defense = 1,
        magic = 11
    },

    -- Weapon icon in equip menu
    weapon_icon = "ui/menu/equip/ring",

    -- Equipment (saved to the save file)
    equipped = {
        weapon = "snow_ring",
        armor = {"silver_watch"}
    },
}