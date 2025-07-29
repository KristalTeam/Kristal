-- VENDor CUSTomizations (Android reference)
-- (an awful name that doesn't even fit, I know...)
-- See also /conf.lua

-- The "target mod"'s ID. (- the one in mod.json) \
-- If set, the main menu is modified to direct the player to start/load a game \
-- of the designated mod, instead of letting them choose which mod to play. \
-- Also set if command parameter `--mod <id>` is passed to the engine. \
-- (The value set here overrides that)
---@type string?
TARGET_MOD = nil

-- Disables Kristal's built-in main menu and immediately loads the target mod.
---@type boolean
AUTO_MOD_START = false

-- Disables or hides various debugging features that are thought to be unnecessary for standalone mod releases,
-- such as the Hotswapper and [the global debug hotkeys](lua://Kristal.onKeyPressed).
--
-- While this hides debug-related options from [`MainMenuOptions`](lua://MainMenuOptions.initializeOptions),
-- they can still be enabled by editing the config file.
---@type boolean
RELEASE_MODE = false