---@class MainMenuModList : StateClass
---
---@field menu MainMenu
---
---@field list ModList
---
---@field mods table[]
---@field fades table<string, number>
---@field music table<string, Music>
---@field music_options table<string, table>
---@field scripts table<string, table>
---@field engine_versions table<string, any[]>
---
---@field loading_mods boolean
---@field last_loaded string[]
---
---@field active boolean
---
---@overload fun(menu:MainMenu) : MainMenuModList
local MainMenuModList, super = Class(StateClass)

function MainMenuModList:init(menu)
    self.menu = menu

    self.list = nil

    self.mods = {}

    self.fades = {}
    self.music = {}
    self.music_options = {}
    self.scripts = {}
    self.engine_versions = {}

    self.loading_mods = false
    self.last_loaded = {}

    self.active = false
end

function MainMenuModList:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuModList:onEnter(old_state)
    self.active = true

    if not self.list then
        self:buildModList()

        if #Kristal.Mods.failed_mods > 0 then
            return "MODERROR"
        end
    elseif #self.list.mods > 0 then
        self.list.active = true
        self.list.visible = true
    end
end

function MainMenuModList:onLeave(new_state)
    if self.list then
        self.list.active = false
        self.list.visible = false
    end

    self.active = false

    self.menu.heart_outline.visible = false
end

function MainMenuModList:onKeyPressed(key, is_repeat)
    if key == "f5" then
        Assets.stopAndPlaySound("ui_select")

        self:reloadMods()
        return true
    end

    if Input.isCancel(key) then
        Assets.stopAndPlaySound("ui_move")

        self.menu:setState("TITLE")
        self.menu.title_screen:selectOption("play")
        return true

    elseif #self.list.mods > 0 then
        local mod = self:getSelectedMod()

        if Input.isConfirm(key) then
            if self.list:isOnCreate() then
                Assets.stopAndPlaySound("ui_select")
                self.menu:setState("MODCREATE")

            elseif mod then
                Assets.stopAndPlaySound("ui_select")
                if (mod["useSaves"] == "has_saves" and (#love.filesystem.getDirectoryItems( "saves/"..mod.id ) > 0))
                or (mod["useSaves"] ~= "has_saves" and mod["useSaves"])
                or (mod["useSaves"] == nil and not mod["encounter"]) then
                    self.menu:setState("FILESELECT")
                else
                    Kristal.loadMod(mod.id)
                end
            end

            return true

        elseif Input.isMenu(key) then
            if mod then
                Assets.stopAndPlaySound("ui_select")

                local is_favorited = Utils.containsValue(Kristal.Config["favorites"], mod.id)
                if is_favorited then
                    Utils.removeFromTable(Kristal.Config["favorites"], mod.id)
                else
                    table.insert(Kristal.Config["favorites"], mod.id)
                end

                Kristal.saveConfig()
                self:buildModListFavorited()
            end

            return true
        end

        if Input.is("up", key) then self.list:selectUp(is_repeat) end
        if Input.is("down", key) then self.list:selectDown(is_repeat) end
        if not Input.isGamepad(key) then
            if Input.is("left", key) and not is_repeat then self.list:pageUp(is_repeat) end
            if Input.is("right", key) and not is_repeat then self.list:pageDown(is_repeat) end
        end
    end
end

function MainMenuModList:update()
    if #self.list.mods == 0 then
        self.menu.heart_target_x = -8
        self.menu.heart_target_y = -8
        self.list.active = false
        self.list.visible = false
        return
    end

    self.list.active = true
    self.list.visible = true

    local button = self:getSelectedButton()

    if button then
        local lhx, lhy = button:getHeartPos()
        local button_heart_x, button_heart_y = button:getRelativePos(lhx, lhy, self.list)
        self.menu.heart_target_x = self.list.x + button_heart_x
        self.menu.heart_target_y = self.list.y + button_heart_y - (self.list.scroll_target - self.list.scroll)
    end

    if button and button:includes(ModButton) then
        ---@cast button ModButton
        self.menu.heart_outline.visible = button:isFavorited()
        self.menu.heart_outline:setColor(button:getFavoritedColor())
    else
        self.menu.heart_outline.visible = false
    end
end

function MainMenuModList:draw()
    if self.loading_mods then
        Draw.printShadow("Loading mods...", 0, 115 - 8, 2, "center", 640)
    else
        local menu_font = Assets.getFont("main")

        if #self.list.mods == 0 then
            -- Draw introduction text if no mods exist

            self.intro_text = {{1, 1, 1, 1}, "Welcome to Kristal,\nthe DELTARUNE fangame engine!\n\nAdd mods to the ", {1, 1, 0, 1}, "mods folder", {1, 1, 1, 1}, "\nto continue."}
            Draw.printShadow(self.intro_text, 0, 160 - 8, 2, "center", 640)

            local string_part_1 = "Press "
            local string_part_2 = Input.getText("cancel")
            local string_part_3 = " to return to the main menu."

            local part_2_width = menu_font:getWidth(string_part_2)
            if Input.usingGamepad() then
                part_2_width = 32
            end

            local total_width = menu_font:getWidth(string_part_1) + part_2_width + menu_font:getWidth(string_part_3)

            -- Draw each part, using total_width to center it
            Draw.setColor(COLORS.silver)
            Draw.printShadow(string_part_1, 320 - (total_width / 2), 480 - 32)

            local part_2_xpos = 320 - (total_width / 2) + menu_font:getWidth(string_part_1)
            if Input.usingGamepad() then
                Draw.setColor(0, 0, 0, 1)
                Draw.draw(Input.getTexture("cancel"), part_2_xpos + 4 + 2, 480 - 32 + 4, 0, 2, 2)
                Draw.setColor(1, 1, 1, 1)
                Draw.draw(Input.getTexture("cancel"), part_2_xpos + 4, 480 - 32 + 2, 0, 2, 2)
            else
                Draw.printShadow(string_part_2, part_2_xpos, 480 - 32)
            end
            Draw.setColor(COLORS.silver)
            Draw.printShadow(string_part_3, 320 - (total_width / 2) + menu_font:getWidth(string_part_1) + part_2_width, 480 - 32)

            Draw.setColor(1, 1, 1)
        else
            -- Draw some menu text
            Draw.printShadow("Choose your world.", 80, 34 - 8)

            local control_menu_width = 0
            local control_cancel_width = 0
            if Input.usingGamepad() then
                control_menu_width = 32
                control_cancel_width = 32
            else
                control_menu_width = menu_font:getWidth(Input.getText("menu"))
                control_cancel_width = menu_font:getWidth(Input.getText("cancel"))
            end

            local button = self:getSelectedButton()
            local favorited = button and button:includes(ModButton) and button:isFavorited()

            local x_pos = menu_font:getWidth(" Back")
            Draw.printShadow(" Back", 580 + (16 * 3) - x_pos, 454 - 8)
            x_pos = x_pos + control_cancel_width
            if Input.usingGamepad() then
                Draw.setColor(0, 0, 0, 1)
                Draw.draw(Input.getTexture("cancel"), 580 + (16 * 3) - x_pos + 2, 454 - 8 + 4, 0, 2, 2)
                Draw.setColor(1, 1, 1, 1)
                Draw.draw(Input.getTexture("cancel"), 580 + (16 * 3) - x_pos, 454 - 8 + 2, 0, 2, 2)
            else
                Draw.printShadow(Input.getText("cancel"), 580 + (16 * 3) - x_pos, 454 - 8)
            end
            local fav = favorited and " Unfavorite  " or " Favorite  "
            x_pos = x_pos + menu_font:getWidth(fav)
            Draw.printShadow(fav, 580 + (16 * 3) - x_pos, 454 - 8)
            x_pos = x_pos + control_menu_width
            if Input.usingGamepad() then
                Draw.setColor(0, 0, 0, 1)
                Draw.draw(Input.getTexture("menu"), 580 + (16 * 3) - x_pos + 2, 454 - 8 + 4, 0, 2, 2)
                Draw.setColor(1, 1, 1, 1)
                Draw.draw(Input.getTexture("menu"), 580 + (16 * 3) - x_pos, 454 - 8 + 2, 0, 2, 2)
            else
                Draw.printShadow(Input.getText("menu"), 580 + (16 * 3) - x_pos, 454 - 8)
            end
            --local control_text = Input.getText("menu").." "..(self.heart_outline.visible and "Unfavorite" or "Favorite  ").."  "..Input.getText("cancel").." Back"
            --Draw.printShadow(control_text, 580 + (16 * 3) - self.menu_font:getWidth(control_text), 454 - 8, {1, 1, 1, 1})
        end
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

---@return table
function MainMenuModList:getSelectedMod()
    return self.list:getSelectedMod()
end

---@return ModButton|ModCreateButton
function MainMenuModList:getSelectedButton()
    return self.list:getSelected()
end

function MainMenuModList:checkCompatibility()
    local mod = self:getSelectedMod()

    if not mod then
        return true, Kristal.Version
    end

    local success = false
    local highest_version

    for _,version in ipairs(self.engine_versions[mod.id]) do
        if not highest_version or highest_version < version then
            highest_version = version
        end
        if version ^ Kristal.Version then
            success = true
        end
    end

    return success, highest_version
end

function MainMenuModList:reloadMods()
    if self.loading_mods then return end

    self.loading_mods = true

    Kristal.Mods.clear()
    Kristal.loadAssets("", "mods", "", function()
        if #Kristal.Mods.failed_mods > 0 then
            self.menu:setState("MODERROR")
        end

        self.loading_mods = false

        Kristal.setDesiredWindowTitleAndIcon()
        self:buildModList()
    end)
end

function MainMenuModList:buildModListFavorited()
    -- Remember the last selected mod
    local last_scroll = self.list and self.list.scroll_target
    local last_selected = self.list and self.list:getSelectedId()
    
    -- Create the mod list object if it doesn't exist
    if not self.list then
        self.list = ModList(69, 70, 502, 370)
        self.list.layer = 50
        self.menu.stage:addChild(self.list)

        if not self.active then
            self.list.active = false
            self.list.visible = false
        end
    else
        self.list:clearMods()
    end
    
    -- Sort them by favorites or filepath
    table.sort(self.mods, function(a, b)
        local a_fav = Utils.containsValue(Kristal.Config["favorites"], a.id)
        local b_fav = Utils.containsValue(Kristal.Config["favorites"], b.id)
        return (a_fav and not b_fav) or (a_fav == b_fav and a.path:lower() < b.path:lower())
    end)
    
    -- Add mods to the list
    for _,mod in ipairs(self.mods) do
        -- Create the mod button
        local button = ModButton(mod.name or mod.id, 424, 62, mod)
        self.list:addMod(button)

        -- Load the mod's preview script
        if mod.preview_script_path then
            local chunk = love.filesystem.load(mod.preview_script_path)
            local success, result = pcall(chunk, mod.path)
            if success then
                button.preview_script = result

                if result.init then
                    result:init(mod, button)
                end
            else
                Kristal.Console:warn("preview.lua error in "..mod.name..": "..result)
            end
        end

        -- Get the engine versions this mod is compatible with
        local engine_ver = mod and mod["engineVer"]
        if type(engine_ver) == "table" then
            local versions = {}
            for _,ver in ipairs(engine_ver) do
                table.insert(versions, SemVer(ver))
            end
            self.engine_versions[mod.id] = versions
        elseif type(engine_ver) == "string" then
            self.engine_versions[mod.id] = {SemVer(engine_ver)}
        else
            self.engine_versions[mod.id] = {Kristal.Version}
        end
    end
    
    -- Add the mod create button
    local create_button = ModCreateButton(424 + 70, 42)
    self.list:addMod(create_button)

    -- Remember the loaded structure of the mods directory
    self.last_loaded = love.filesystem.getDirectoryItems("mods")

    -- Keep the list scrolled at the previously selected mod, if it exists, or start at the first mod
    local keep_button, keep_index = self.list:getById(last_selected)
    if last_selected and keep_button then
        self.list:select(keep_index, true)
        self.list:setScroll(last_scroll)
    else
        self.list:select(1, true)
    end
    
    -- Hide list if there are no mods
    if #self.list.mods == 0 then
        self.list.active = false
        self.list.visible = false
    end
end

function MainMenuModList:buildModList()
    -- Remember the last selected mod
    local last_scroll = self.list and self.list.scroll_target
    local last_selected = self.list and self.list:getSelectedId()

    -- Create the mod list object if it doesn't exist
    if not self.list then
        self.list = ModList(69, 70, 502, 370)
        self.list.layer = 50
        self.menu.stage:addChild(self.list)

        if not self.active then
            self.list.active = false
            self.list.visible = false
        end
    else
        self.list:clearMods()
    end

    -- Remove all existing mod music
    for _, music in pairs(self.music) do
        music:remove()
    end

    -- Clear old tables
    self.fades = {}
    self.music = {}
    self.music_options = {}
    self.backgrounds = {}
    self.scripts = {}
    self.engine_versions = {}

    -- Get all non-hidden mods for the mod list
    self.mods = Utils.filter(Kristal.Mods.getMods(), function(mod) return not mod.hidden end)

    -- Sort them by favorites or filepath
    table.sort(self.mods, function(a, b)
        local a_fav = Utils.containsValue(Kristal.Config["favorites"], a.id)
        local b_fav = Utils.containsValue(Kristal.Config["favorites"], b.id)
        return (a_fav and not b_fav) or (a_fav == b_fav and a.path:lower() < b.path:lower())
    end)

    -- Add mods to the list
    for _,mod in ipairs(self.mods) do
        -- Create the mod button
        local button = ModButton(mod.name or mod.id, 424, 62, mod)
        self.list:addMod(button)

        -- Initialize the mod's fader (for background and music fading)
        self.fades[mod.id] = 0

        -- Load the mod's preview script
        if mod.preview_script_path then
            local chunk = love.filesystem.load(mod.preview_script_path)
            local success, result = pcall(chunk, mod.path)
            if success then
                self.scripts[mod.id] = result
                button.preview_script = result

                if result.init then
                    result:init(mod, button)
                end
            else
                Kristal.Console:warn("preview.lua error in "..mod.name..": "..result)
            end
        end

        -- Load the mod's preview music
        if mod.preview_music_path then
            self.music_options[mod.id] = {
                volume = mod["previewVolume"]     or 1,
                sync   = mod["previewMusicSync"]  or false,
                pause  = mod["previewMusicPause"] or false,
                loop   = mod["previewMusicLoop"] == nil and true or mod["previewMusicLoop"],
            }

            local music = Music()
            music:playFile(mod.preview_music_path, 0, 1)
            music:setLooping(self.music_options[mod.id].loop)
            music:stop()

            self.music[mod.id] = music
        end

        -- Get the engine versions this mod is compatible with
        local engine_ver = mod and mod["engineVer"]
        if type(engine_ver) == "table" then
            local versions = {}
            for _,ver in ipairs(engine_ver) do
                table.insert(versions, SemVer(ver))
            end
            self.engine_versions[mod.id] = versions
        elseif type(engine_ver) == "string" then
            self.engine_versions[mod.id] = {SemVer(engine_ver)}
        else
            self.engine_versions[mod.id] = {Kristal.Version}
        end
    end

    -- Add the mod create button
    local create_button = ModCreateButton(424 + 70, 42)
    self.list:addMod(create_button)

    -- Remember the loaded structure of the mods directory
    self.last_loaded = love.filesystem.getDirectoryItems("mods")

    -- Keep the list scrolled at the previously selected mod, if it exists, or start at the first mod
    local keep_button, keep_index = self.list:getById(last_selected)
    if last_selected and keep_button then
        self.list:select(keep_index, true)
        self.list:setScroll(last_scroll)
    else
        self.list:select(1, true)
    end

    -- TODO: Mod menus
    if TARGET_MOD then
        local target_button,index = self.list:getById(TARGET_MOD)
        if not index then
            error("No mod found: "..TARGET_MOD)
        else
            self.list:select(index, true)
        end

        if self.fades[TARGET_MOD] then
            self.fades[TARGET_MOD] = 1

            if self.scripts[TARGET_MOD] and self.scripts[TARGET_MOD].hide_background ~= false then
                self.menu.background_fade = 0
            end
        end

        if self.music[TARGET_MOD] then
            self.menu.music:remove()

            self.menu.music = self.music[TARGET_MOD]
            self.menu.music:setVolume(self.music_options[TARGET_MOD].volume)
            self.menu.music:play()
        end
    end

    -- Hide list if there are no mods
    if #self.list.mods == 0 then
        self.list.active = false
        self.list.visible = false
    end
end

return MainMenuModList