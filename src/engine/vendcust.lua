-- VENDor CUSTomizations (Android reference)
-- (an awful name that doesn't even fit, I know...)
-- See also /conf.lua

--- The ID of the "target mod" (found in mod.json).
---
--- If set, the start menu is modified to direct the player to start/load a game
--- of the designated mod, instead of letting them choose which mod to play.
---
--- Also set if command parameter `--mod <id>` is passed to the engine, though this value overrides that.
---@type string
TARGET_MOD = nil

--- Disables Kristal's built-in Main menu and
--- immediately loads the target mod.
---@type boolean
AUTO_MOD_START = false

--- Controls whether Kristal development-related features are enabled or not.
---
--- For official builds, this is true. In interm builds, this is false.
RELEASE_MODE = false
