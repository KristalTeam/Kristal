return {
    -- The ID of your mod. Should be unique!!
    id = "{id}",
    -- Displays on the main menu.
    name = "{name}",
    -- Displays underneath the name. Optional.
    subtitle = "",

    -- The version of your mod.
    version = "v1.0.0",
    -- What version of the engine your mod was made with.
    engineVer = "{engineVer}",

    -- The Deltarune chapter you'd like to base your mod off of.
    -- Do keep in mind that you can control chapter-specific features
    -- one by one using the config below.
    chapter = {chapter},

    -- The map that you start in when first starting the mod.
    map = "room1",

    -- The party. The first character is the player.
    party = {"kris", "susie", "ralsei"},

    -- The inventory. Contains three darkburgers, a cell phone, and a shadow crystal by default.
    inventory = {
        items = {"glowshard", "darkburger", "darkburger", "darkburger"},
        key_items = {"cell_phone", "shadowcrystal"},
    },

    -- Equipment for your party. Not specifying equipment defaults to the following:
    equipment = {
        kris = {
            weapon = "wood_blade",
            armor = {"amber_card", "amber_card"},
        },
        susie = {
            weapon = "mane_ax",
            armor = {"amber_card", "amber_card"},
        },
        ralsei = {
            weapon = "red_scarf",
            armor = {"amber_card", "amber_card"},
        }
    },

    -- Should never be true, but just in case. Restarts the entire engine when leaving the mod.
    -- If you need this, you're most likely doing something wrong.
    hardReset = false,

    -- Whether the mod is hidden from mod selection.
    hidden = false,

    -- Whether the game window's title should be set to the mod's menu, and the icon to the image
    -- in the file `window_icon.png`.
    -- When your mod is configured as the engine's target mod, it's automatically done unless if
    -- this option is explicitly set to false; else, it's done if this is set to true.
    setWindowTitleAndIcon = nil,

    -- Config values for the engine and any libraries you may have.
    -- These config values can control chapter-specific features as well.
    config = {
        kristal = {
{config}
        }
    }
}