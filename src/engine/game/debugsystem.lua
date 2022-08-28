local DebugSystem, super = Class(Object)

function DebugSystem:init()
    super:init(self, 0, 0)
    self.layer = 10000000 - 2

    self.font_size = 32
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.heart = Sprite("player/heart_menu")
    self.heart.visible = true
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setScale(2, 2)
    self.heart:setColor(1, 0, 0)
    self.heart.layer = 100
    self:addChild(self.heart)

    self.heart_target_x = -10
    self.heart_target_y = -10

    -- States: IDLE, MENU, MOUSE
    self.state = "IDLE"
    self.old_state = "IDLE"
    self.state_reason = nil

    self.current_selecting = 1

    self.current_subselecting = 1

    self.menu_canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    self.menu_canvas:setFilter("nearest", "nearest")

    self.menus = {}

    self:refresh()

    self.current_menu = "main"

    self.menu_anim_timer = 1
    self.circle_anim_timer = 1

    self.menu_history = {}

    self.object = nil
    self.last_object = nil
    self.flash_fx = self:addFX(ColorMaskFX())
    self.flash_fx:setColor(1, 1, 1)
    self.flash_fx.amount = 0
    self.grabbing = false
    self.grab_offset_x = 0
    self.grab_offset_y = 0
    self.hover_alpha = 0
    self.last_hovered = nil
    self.selected_alpha = 0
    self.current_text_align = "left"
    self.release_timer = 0

    self.copied_object = nil
    self.copied_object_parent = nil
    self.copied_object_temp = false

    self.context = nil
    self.last_context = nil

    self.search_text = {""}

    self.menu_y = 0
    self.menu_target_y = 0
end

function DebugSystem:getStage()
    if Gamestate.current() then
        return Gamestate.current().stage
    end
end

function DebugSystem:mouseOpen()
    return self.state == "MOUSE"
end

function DebugSystem:selectObject(object)
    self:unselectObject()
    self.object = object
    self.last_object = object
    self.object:addFX(self.flash_fx, "debug_flash")
end

function DebugSystem:onMousePressed(x, y, button, istouch, presses)
    if self.window then
        self.window:onMousePressed(x, y, button, istouch, presses)
        return
    end

    if self.context then
        if self.context:onMousePressed(x, y, button, istouch, presses) then
            return
        end
    end

    if button == 3 then
        if self:mouseOpen() then
            self:closeMouse()
        else
            self:openMouse()
        end
        return
    end

    if self:mouseOpen() then
        if button == 1 or button == 2 then
            local object = self:detectObject(Input.getMousePosition())

            if object then
                self:selectObject(object)
                self.grabbing = (button == 1) -- right clicking should not drag
                local screen_x, screen_y = object:getScreenPos()
                self.grab_offset_x = x - screen_x
                self.grab_offset_y = y - screen_y
            else
                self:unselectObject()
            end

            if button == 2 then
                if self.object then
                    self:openObjectContext(self.object)
                else
                    self.context = ContextMenu("Debug")
                    if Game.world then
                        if Game.world.player then
                            self.context:addMenuItem("Teleport", "Teleport the player to\nthe current position.", function()
                                Game.world.player:setScreenPos(Input.getMousePosition())
                                Game.world.player:interpolateFollowers()
                                self:selectObject(Game.world.player)
                            end)
                        else
                            self.context:addMenuItem("Spawn player", "Spawn the player at the\ncurrent position.", function()
                                Game.world:spawnPlayer(0, 0, Game.party[1]:getActor())
                                Game.world.player:setScreenPos(Input.getMousePosition())
                                Game.world.player:interpolateFollowers()
                                self:selectObject(Game.world.player)
                            end)
                        end
                    end
                    if self.copied_object then
                        self.context:addMenuItem("Paste", "Paste the copied object.", function()
                            self:pasteObject()
                        end)
                    end
                    self.context:addMenuItem("Select object", "Select an object by name.", function()
                        self.window = DebugWindow("Select Object", "Enter the name of the object to select.", "input", function(text)
                            local stage = self:getStage()
                            if stage then
                                local objects = stage:getObjects()
                                Object.startCache()
                                for _,instance in ipairs(objects) do
                                    if Utils.getClassName(instance):lower() == text:lower() then
                                        self:selectObject(instance)
                                        self:openObjectContext(instance)
                                        break
                                    end
                                end
                                Object.endCache()
                            end
                        end)
                        self.window:setPosition(Input.getMousePosition())
                        self:addChild(self.window)
                    end)
                    Kristal.callEvent("registerDebugContext", self.context, nil)
                    self.context:setPosition(Input.getMousePosition())
                    self:addChild(self.context)
                end
            end
        end
    end
end

function DebugSystem:openObjectContext(object)
    self.context = object:getDebugOptions(ContextMenu(Utils.getClassName(object)))
    self.last_context = self.context

    Kristal.callEvent("registerDebugContext", self.context, self.object)
    self.context:setPosition(Input.getMousePosition())
    self:addChild(self.context)
end

function DebugSystem:copyObject(object)
    self.copied_object = object:clone()
    self.copied_object:removeFX("debug_flash")
    self.copied_object_temp = false
    self.copied_object_parent = object.parent
end

function DebugSystem:cutObject(object)
    self.copied_object = object
    self.copied_object_parent = object.parent
    self.copied_object_temp = true
    self:unselectObject()
    object:remove()
end

function DebugSystem:pasteObject(object)
    if not self.copied_object then return end

    local new_object = self.copied_object_temp and self.copied_object or self.copied_object:clone()

    if not new_object then return end

    if object then
        -- We're pasting into another object
        object:addChild(new_object)
    else
        -- We're not pasting into an object
        if self.copied_object_parent then
            self.copied_object_parent:addChild(new_object)
        else
            self:getStage():addChild(new_object)
        end
    end

    new_object:setScreenPos(Input.getMousePosition())
    self:selectObject(new_object)
    if self.copied_object_temp then
        self.copied_object = nil
        self.copied_object_parent = nil
        self.copied_object_temp = false
    end
end

function DebugSystem:unselectObject()
    if self.object then
        self.object:removeFX(self.flash_fx)
    end
    self.object = nil
    self.grabbing = false
end

function DebugSystem:onMouseReleased(x, y, button, istouch, presses)
    if self.window then
        self.grabbing = false
        self.window:onMouseReleased(x, y, button, istouch, presses)
        return
    end

    if self.context then
        self.context:onMouseReleased(x, y, button, istouch, presses)
    end
    if button == 1 or button == 2 then
        if self.grabbing then
            self.grabbing = false
        end
    end
end

function DebugSystem:detectObject(x, y)
    -- TODO: Z-Order should take priority!!
    local object_size = math.huge
    local hierarchy_size = -1
    local found = false
    local object = nil

    local stage = self:getStage()
    if stage then
        local objects = stage:getObjects()
        Object.startCache()
        for _,instance in ipairs(objects) do
            if instance:canDebugSelect() and instance:isFullyVisible() then
                local mx, my = instance:getFullTransform():inverseTransformPoint(x, y)
                local rect = instance:getDebugRectangle() or {0, 0, instance.width, instance.height}
                if mx >= rect[1] and mx < rect[1]+rect[3] and my >= rect[2] and my < rect[2]+rect[4] then
                    local new_hierarchy_size = #instance:getHierarchy()
                    local new_object_size = math.sqrt(rect[3] * rect[4])
                    if new_hierarchy_size > hierarchy_size or (new_hierarchy_size == hierarchy_size and new_object_size < object_size) then
                        hierarchy_size = new_hierarchy_size
                        object_size = new_object_size
                        object = instance
                        found = true
                    end
                end
            end
        end
        Object.endCache()
    end
    return object
end

function DebugSystem:registerConfigOption(menu, name, description, value, callback)
    self:registerOption(menu, name, function()
        return self:appendBool(description, Kristal.Config[value])
    end, function()
        Kristal.Config[value] = not Kristal.Config[value]
        if callback then
            callback()
        end
    end)
end

function DebugSystem:appendBool(desc, bool)
    return desc .. (bool and " (ON)" or " (OFF)")
end

function DebugSystem:refresh()
    self.menus = {}
    self:registerMenu("main", "~ KRISTAL DEBUG ~")
    self.current_menu = "main"
    self:registerDefaults()
    self:registerSubMenus()
    Kristal.callEvent("registerDebugOptions", self)
end

function DebugSystem:returnMenu()
    Input.clear("confirm")
    Input.clear("cancel")
    if #self.menu_history == 0 then
        self:closeMenu()
    else
        self:enterMenu(self.menu_history[#self.menu_history].name, self.menu_history[#self.menu_history].soul, true)
        table.remove(self.menu_history, #self.menu_history)
    end
end

function DebugSystem:registerMenu(id, name, type)
    self.menus[id] = {
        name = name,
        options = {},
        type = type or "menu",
    }
end

function DebugSystem:enterMenu(menu, soul, skip_history)
    if not skip_history then
        table.insert(self.menu_history, {
            name = self.current_menu,
            soul = self.current_selecting
        })
    end
    self.current_menu = menu
    self.current_selecting = soul or 1

    if self.menus[self.current_menu].type == "search" then
        self.search = {""}
        --self:sortMenuOptions(self.current_menu)

        self:startTextInput()
    end
end

function DebugSystem:startTextInput()
    TextInput.attachInput(self.search, {
        multiline = false,
        enter_submits = true,
        clear_after_submit = false
    })

    TextInput.submit_callback = function(...)
        Assets.playSound("ui_select")
        self.current_selecting = self.current_selecting + 1
        self:updateBounds(self:getValidOptions())
        if (self.current_selecting ~= 0) then
            TextInput.endInput()
        end
        --love.keyboard.setKeyRepeat(true)
    end

    Input.clear("down")
    Input.clear("gamepad:lsdown")
    Input.clear("gamepad:dpdown")

    TextInput.pressed_callback = function(key)
        if not Input.processKeyPressedFunc(key) then return end

        if key == "down" or key == "gamepad:lsdown" or key == "gamepad:dpdown" then
            TextInput.endInput()

            if self.current_selecting < #self:getValidOptions() then
                Assets.playSound("ui_move")
                self.current_selecting = self.current_selecting + 1
            end
            --love.keyboard.setKeyRepeat(true)
        end
    end
end

function DebugSystem:sortMenuOptions(options, filter)
    table.sort(options, function(a, b)
        return a.name < b.name
    end)
    if filter then

        local copied_options = Utils.copy(options)

        -- Make two tables, one for starting WITH the filter, and one for CONTAINING the filter.

        local start_with = {}
        for i = #copied_options, 1, -1 do
            local item = copied_options[i]
            if Utils.startsWith(item.name:lower(), filter:lower()) then
                table.insert(start_with, 1, item)
                table.remove(copied_options, i)
            end
        end

        local contains = {}
        for i = #copied_options, 1, -1 do
            local item = copied_options[i]
            if Utils.contains(item.name:lower(), filter:lower()) then
                table.insert(contains, 1, item)
                table.remove(copied_options, i)
            end
        end

        Utils.clear(options)
        for _,item in ipairs(start_with) do
            table.insert(options, item)
        end

        for _,item in ipairs(contains) do
            table.insert(options, item)
        end
    end
end

function DebugSystem:registerSubMenus()
    self:registerMenu("engine_options", "Engine Options")
    self:registerConfigOption("engine_options", "Show FPS", "Toggle the FPS display.", "showFPS")
    self:registerOption("engine_options", "Target FPS", function()
        local fps_text = Kristal.Config["fps"] > 0 and tostring(Kristal.Config["fps"]) or "Unlimited"
        return "Set the target FPS. ("..fps_text..")"
    end, function()
        self:enterMenu("engine_option_fps", 1)
    end)
    self:registerConfigOption("engine_options", "VSync", "Toggle Vsync.", "vSync", function()
        love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)
    end)
    self:registerOption("engine_options", "Print Performance", "Show performance in the console.", function() PERFORMANCE_TEST_STAGE = "UPDATE" end)
    self:registerOption("engine_options", "Back", "Go back to the previous menu.", function() self:returnMenu() end)

    self:registerMenu("engine_option_fps", "Target FPS")
    self:registerOption("engine_option_fps", "Unlimited", "Set the target FPS to unlimited.", function() Kristal.Config["fps"] = 0; FRAMERATE = 0 end)
    self:registerOption("engine_option_fps", "30", "Set the target FPS to 30.", function() Kristal.Config["fps"] = 30; FRAMERATE = 30 end)
    self:registerOption("engine_option_fps", "60", "Set the target FPS to 60.", function() Kristal.Config["fps"] = 60; FRAMERATE = 60 end)
    self:registerOption("engine_option_fps", "120", "Set the target FPS to 120.", function() Kristal.Config["fps"] = 120; FRAMERATE = 120 end)
    self:registerOption("engine_option_fps", "144", "Set the target FPS to 144.", function() Kristal.Config["fps"] = 144; FRAMERATE = 144 end)
    self:registerOption("engine_option_fps", "240", "Set the target FPS to 240.", function() Kristal.Config["fps"] = 240; FRAMERATE = 240 end)
    self:registerOption("engine_option_fps", "Back", "Go back to the previous menu.", function() self:returnMenu() end)

    self:registerMenu("give_item", "Give Item", "search")

    for id, item_data in pairs(Registry.items) do
        local item = item_data()
        self:registerOption("give_item", item.name, item.description, function()
            Game.inventory:tryGiveItem(item)
        end)
    end

    self:registerMenu("select_map", "Select Map", "search")
    -- Registry.map_data instead of Registry.maps
    for id,_ in pairs(Registry.map_data) do
        self:registerOption("select_map", id, "Teleport to this map.", function()
            if Game.world.cutscene then
                Game.world:stopCutscene()
            end
            Game.lock_movement = false
            Game.world:loadMap(id)
            self:closeMenu()
        end)
    end


    self:registerMenu("encounter_select", "Encounter Select", "search")
    -- loop through registry and add menu options for all encounters
    for id,_ in pairs(Registry.encounters) do
        self:registerOption("encounter_select", id, "Start this encounter.", function()
            Game:encounter(id)
            self:closeMenu()
        end)
    end

    self:registerMenu("cutscene_select", "Cutscene Select", "search")
    -- loop through registry and add menu options for all cutscenes
    for group,cutscene in pairs(Registry.world_cutscenes) do
        if type(cutscene) == "table" then
            for id,_ in pairs(cutscene) do
                self:registerOption("cutscene_select", group.."."..id, "Start this cutscene.", function()
                    Game.world:startCutscene(group, id)
                    self:closeMenu()
                end)
            end
        else
            self:registerOption("cutscene_select", group, "Start this cutscene.", function()
                Game.world:startCutscene(group)
                self:closeMenu()
            end)
        end
    end
end

function DebugSystem:registerDefaults()
    -- Global
    self:registerConfigOption("main", "Object Selection Pausing", "Pauses the game when the object selection menu is opened.", "objectSelectionSlowdown")

    self:registerOption("main", "Engine Options", "Configure various noningame options.", function()
        self:enterMenu("engine_options", 1)
    end)

    self:registerOption("main", "Fast Forward", function() return self:appendBool("Speed up the engine.", FAST_FORWARD) end, function() FAST_FORWARD = not FAST_FORWARD end)
    self:registerOption("main", "Debug Rendering", function() return self:appendBool("Draw debug information.", DEBUG_RENDER) end, function() DEBUG_RENDER = not DEBUG_RENDER end)
    self:registerOption("main", "Hotswap", "Swap out code from the files. Might be unstable.", function() Hotswapper.scan(); self:refresh() end)
    self:registerOption("main", "Reload", "Reload the mod. Hold shift to\nnot temporarily save.", function()
        if Kristal.getModOption("hardReset") then
            love.event.quit("restart")
        else
            if Mod then
                Kristal.quickReload(Input.shift())
            else
                Kristal.returnToMenu()
            end
        end
    end)

    self:registerOption("main", "Noclip", function() return self:appendBool("Toggle interaction with solids.", NOCLIP) end, function() NOCLIP = not NOCLIP end)

    -- Need a way to specify whether something should show up in the Kristal main menu or not
    -- (or just non-gameplay states)
    self:registerOption("main", "Give Item", "Give an item.", function()
        self:enterMenu("give_item", 0)
    end)

    -- World specific
    self:registerOption("main", "Select Map", "Switch to a new map.", function()
        self:enterMenu("select_map", 0)
    end, "OVERWORLD")

    self:registerOption("main", "Start Encounter", "Start an encounter.", function()
        self:enterMenu("encounter_select", 0)
    end, "OVERWORLD")

    self:registerOption("main", "Play Cutscene", "Play a cutscene.", function()
        self:enterMenu("cutscene_select", 0)
    end, "OVERWORLD")

    -- Battle specific
    self:registerOption("main", "End Battle", "Instantly complete a battle.", function() Game.battle:setState("VICTORY") end, "BATTLE")
end

function DebugSystem:getValidOptions()
    local options = {}
    for i, v in ipairs(self.menus[self.current_menu].options) do
        if (Game and v.state == Game.state)
           or v.state == "ALL" then

            table.insert(options, v)
        end
    end
    if self.menus[self.current_menu].type == "search" then
        self:sortMenuOptions(options, self.search[1])
    end
    self:updateBounds(options)
    return options
end

function DebugSystem:registerOption(menu, name, description, func, state)
    table.insert(self.menus[menu].options, {name=name, description=description, func=func, state=state or "ALL"})
end

function DebugSystem:openMouse()
    Assets.playSound("ui_select")
    self:setState("MOUSE")
end

function DebugSystem:closeMouse()
    Assets.playSound("ui_move")
    self:setState("IDLE")
end

function DebugSystem:openMenu()
    Assets.playSound("ui_select")
    self:setState("MENU")
end

function DebugSystem:closeMenu()
    self:setState("IDLE")
end

function DebugSystem:setState(state, reason)
    self.old_state = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(self.old_state, self.state)
end

function DebugSystem:onStateChange(old, new)
    self.heart_target_x = -10
    if new == "MENU" then
        self.heart_target_x = 19
        self.heart_target_y = 35 + 32

        self.menu_anim_timer = 0
        self.circle_anim_timer = 0
        OVERLAY_OPEN = true

        Kristal.showCursor()
        --love.keyboard.setKeyRepeat(true) -- TODO: Text repeat stack
    elseif new == "MOUSE" then
        self.last_object = nil
        self.menu_anim_timer = 0
        self.circle_anim_timer = 0
        Kristal.showCursor()
    elseif new == "IDLE" then
        self:unselectObject()
        self.menu_anim_timer = 0
        OVERLAY_OPEN = false

        Kristal.hideCursor()
        --love.keyboard.setKeyRepeat(false)
    end
end

function DebugSystem:updateBounds(options)
    local limit = (self.menus[self.current_menu].type == "search") and 0 or 1
    if self.current_selecting < limit then self.current_selecting = #options end
    if self.current_selecting > #options then self.current_selecting = limit end
    if self.state == "MENU" then
        self.heart_target_x = 19
        local is_search = (self.menus[self.current_menu].type == "search")

        local y_off = (self.current_selecting - 1) * 32

        if y_off + self.menu_target_y < 0 then
            self.menu_target_y = self.menu_target_y + (0 - (y_off + self.menu_target_y))
        end

        local scroll_limit = is_search and 8 or 10

        if y_off + self.menu_target_y > (scroll_limit * 32) then
            self.menu_target_y = self.menu_target_y + ((scroll_limit * 32) - (y_off + self.menu_target_y))
        end



        self.heart_target_y = (self.current_selecting - 1) * 32 + 35 + 32 + (is_search and 64 or 0) + self.menu_target_y
        if (self.current_selecting == 0) and is_search then
            self.heart_target_x = self.heart_target_x + 128 - 6
            self.heart_target_y = self.heart_target_y - 32 + 16 - self.menu_target_y
            self.menu_target_y = 0
        end
    end
end

function DebugSystem:onKeyPressed(key, is_repeat)
    if not Input.processKeyPressedFunc(key, is_repeat) then return end

    if Input.is("object_selector", key) and not is_repeat then
        if self:mouseOpen() then
            self:closeMouse()
        else
            self:openMouse()
        end
        return
    end

    if TextInput.active then return end

    if self.state == "MENU" then

        local options = self:getValidOptions()
        if Input.isCancel(key) then
            Assets.playSound("ui_move")
            self:returnMenu()
            return
        end
        if Input.isConfirm(key) then
            local option = options[self.current_selecting]
            if option then
                Assets.playSound("ui_select")
                option.func()
            end
        end

        local is_search = (self.menus[self.current_menu].type == "search")
        local limit = is_search and 0 or 1
        if Input.is("down", key) and (not is_repeat or self.current_selecting < #options) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting + 1
        end
        if Input.is("up", key) and (not is_repeat or self.current_selecting > limit) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting - 1
        end
        self:updateBounds(options)
        if is_search and (self.current_selecting == 0) and not TextInput.active then
            self:startTextInput()
        end
    elseif self.state == "MOUSE" and not is_repeat then
        if (key == "c") and Input.ctrl() and self.object then
            self:copyObject(self.object)
        elseif (key == "x") and Input.ctrl() and self.object then
            self:cutObject(self.object)
        elseif (key == "v") and Input.ctrl() then
            self:pasteObject()
        elseif (key == "delete") and self.object then
            self.object:remove()
            self:unselectObject()
        end
    end
end

function DebugSystem:isMenuOpen()
    return self.state == "MENU"
end

function DebugSystem:update()
    local stage = self:getStage()

    self.release_timer = self.release_timer + (DT * (stage and stage.timescale or 1))
    if self.grabbing then
        self.release_timer = 0
    end
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT

    if (math.abs((self.menu_target_y - self.menu_y)) <= 2) then
        self.menu_y = self.menu_target_y
    end
    self.menu_y = self.menu_y + ((self.menu_target_y - self.menu_y) / 2) * DTMULT

    if self.object and self.object:isRemoved() then
        self:unselectObject()
    end

    if self.copied_object_parent and self.copied_object_parent.stage ~= self:getStage() then
        self.copied_object_parent = nil
    end

    -- Update grabbed object
    if self.grabbing then
        if self.object then
            local x, y = Input.getMousePosition()
            self.object:setScreenPos(x - self.grab_offset_x, y - self.grab_offset_y)
            self.object.debug_x, self.object.debug_y = self.object.x, self.object.y
        end
    end

    self.menu_anim_timer = self.menu_anim_timer + DT / 0.5 -- 0.5 seconds
    self.circle_anim_timer = self.circle_anim_timer + DT / 0.5

    self.flash_fx:setColor(1, 1, 1)
    self.flash_fx.amount = -math.cos((love.timer.getTime() * 30) / 5) * 0.4 + 0.6

    if stage then
        if self.state == "MOUSE" and Kristal.Config["objectSelectionSlowdown"] then
            stage.timescale = math.max(stage.timescale - (DT / 0.6), 0)
            if stage.timescale == 0 then
                stage.active = false
                stage:updateAllLayers()
            end
        else
            stage.timescale = math.min(stage.timescale + (DT / 0.6), 1)
            stage.active = true
        end
    end
    super:update(self)
end

function DebugSystem:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)

    local menu_x = 0
    local menu_y = 0
    local menu_alpha = 0
    local circle_alpha = 1

    local circle_progress = Utils.lerp(0, 2, self.circle_anim_timer/1.4, true)

    if self.state ~= "IDLE" then
        menu_y = Utils.ease(-32, 0, self.menu_anim_timer, "outExpo")
        menu_alpha = Utils.ease(0, 1, self.menu_anim_timer, "outExpo")
    else
        menu_y = Utils.ease(0, -32, self.menu_anim_timer, "outExpo")
        menu_alpha = Utils.ease(1, 0, self.menu_anim_timer, "outExpo")
        circle_alpha = Utils.lerp(1, 0, self.menu_anim_timer/1.4, true)
    end

    local text_offset = menu_x + 19
    local y_off = 32

    Draw.setCanvas(self.menu_canvas)
    love.graphics.clear()

    local header_name = "UNKNOWN"

    if self.state == "MENU" or (self.old_state == "MENU" and self.state == "IDLE" and (menu_alpha > 0)) then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

        local is_search = (self.menus[self.current_menu].type == "search")

        if is_search then
            local line_width = 320
            -- Get the left size of the line if it's centered
            local x = (640 - line_width) / 2
            local y = y_off + menu_y + 32

            love.graphics.setLineWidth(2)
            local line_x  = x
            local line_x2 = line_x + line_width
            local line_y = 32 - 4 - 1 + 2
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.line(line_x + 2, y + line_y + 2, line_x2 + 2, y + line_y + 2)
            love.graphics.setColor(COLORS.silver)
            love.graphics.line(line_x, y + line_y, line_x2, y + line_y)

            TextInput.draw({
                x = x,
                y = y,
                font = self.font,
                print = function(text, x, y) self:printShadow(text, x, y) end,
            })
        end

        header_name = self.menus[self.current_menu].name

        local search_off = (is_search and 64 or 0)

        Draw.pushScissor()
        Draw.scissor(text_offset + 19, y_off + menu_y + 16 + search_off, 480, 320 + 48 - search_off)

        local options = self:getValidOptions()
        for index, option in ipairs(options) do
            local name = option.name
            if type(name) == "function" then
                name = name()
            end
            self:printShadow(name, text_offset + 19, y_off + menu_y + (index - 1) * 32 + 16 + (is_search and 64 or 0) + self.menu_y)
        end
        Draw.popScissor()

        local option = options[self.current_selecting]
        if option and option.description then
            local description = option.description
            if type(description) == "function" then
                description = description()
            end
            local width, wrapped = self.font:getWrap(description, 580)
            for i, line in ipairs(wrapped) do
                self:printShadow(line, 0, 480 + (32 * i) - (32 * (#wrapped + 1)), COLORS.gray, "center", 640)
            end
        end

    elseif self.state == "MOUSE" or (self.old_state == "MOUSE" and self.state == "IDLE" and (menu_alpha > 0)) then
        header_name = "~ OBJECT SELECTION ~"

        local mx, my = Input.getMousePosition()

        for i = 1, 2 do
            local prog = circle_progress - (i - 1) * 0.4
            if prog >= 0 then
                love.graphics.setLineWidth(2)
                local r = prog * 40
                alpha = 2 - (prog*1.2)
                love.graphics.setColor(0, 1, 1, alpha * circle_alpha)
                love.graphics.circle("line", mx, my, r, 100)
            end
        end

        Object.startCache()
        local mx, my = Input.getMousePosition()

        local object = self.object
        if (not self.grabbing) and (not self.context) then
            object = self:detectObject(mx, my)
        end

        local fadespeed = 0.2
        if object or (self.hover_alpha > 0 and self.last_hovered) then
            local useobject = object
            if not object then
                useobject = self.last_hovered
            else
                self.last_hovered = object
                self.hover_alpha = Utils.clamp(self.hover_alpha + DT / fadespeed, 0, 1)
            end
            love.graphics.setColor(0, 1, 1, self.hover_alpha)
            love.graphics.setLineWidth(1)
            local transform = useobject:getFullTransform()
            love.graphics.push()
            love.graphics.origin()
            love.graphics.applyTransform(transform)
            local rect = useobject:getDebugRectangle() or {0, 0, useobject.width, useobject.height}
            love.graphics.rectangle("line", rect[1], rect[2], rect[3], rect[4])
            love.graphics.pop()

            local tooltip_font = Assets.getFont("main", 16)
            local tooltip_text = Utils.getClassName(useobject)

            local tooltip_width = tooltip_font:getWidth(tooltip_text)
            local tooltip_height = tooltip_font:getHeight()

            local tooltip_x = mx + 8
            local tooltip_y = my - tooltip_font:getHeight()

            if tooltip_x + tooltip_width > SCREEN_WIDTH then
                tooltip_x = mx - tooltip_width - 4
            end

            if tooltip_y < 0 then
                tooltip_y = my + tooltip_font:getHeight()
            end

            local tooltip_alpha = self.hover_alpha
            if self.last_context then
                tooltip_alpha = tooltip_alpha * (1 - (self.last_context.anim_timer/0.2))
            end
            tooltip_x = tooltip_x + Utils.ease(0, 1, (1 - tooltip_alpha), "inCubic") * 10

            love.graphics.setFont(tooltip_font)
            love.graphics.setColor(0, 0, 0, tooltip_alpha)
            love.graphics.print(tooltip_text, tooltip_x-1, tooltip_y)
            love.graphics.print(tooltip_text, tooltip_x+1, tooltip_y)
            love.graphics.print(tooltip_text, tooltip_x, tooltip_y-1)
            love.graphics.print(tooltip_text, tooltip_x, tooltip_y+1)
            love.graphics.setColor(1, 1, 1, tooltip_alpha)
            love.graphics.print(tooltip_text, tooltip_x, tooltip_y)
        end

        if not object then
            self.hover_alpha = self.hover_alpha - DT / fadespeed
        end

        object = self.object
        if (not object) then
            object = self.last_object
        end

        if object then
            local screen_x, screen_y = object:getScreenPos()

            local target_text_align = screen_x < SCREEN_WIDTH/2 and "right" or "left"
            if self.selected_alpha == 0 then
                self.current_text_align = target_text_align
            end

            if self.object and self.current_text_align == target_text_align and not Kristal.Console.is_open then
                self.selected_alpha = Utils.clamp(self.selected_alpha + (DT / 0.2), 0, 1)
            else
                self.selected_alpha = Utils.clamp(self.selected_alpha - (DT / 0.2), 0, 1)
            end

            if self.selected_alpha == 0 then
                self.last_object = nil
            end

            local slide = Utils.ease(0, 1, (1 - self.selected_alpha), "inCubic") * 40

            local x_offset = 12 - slide
            if self.current_text_align == "right" then
                x_offset = 12 + slide
            end
            local limit = SCREEN_WIDTH - 24

            local inc = 1
            self:printShadow("Selected: " .. Utils.getClassName(object),                x_offset, (32 * inc) + 10, {1, 1, 1, self.selected_alpha}, self.current_text_align, limit) inc = inc + 1
            self:printShadow(string.format("Position: (%i, %i)",   object.x, object.y), x_offset, (32 * inc) + 10, {1, 1, 1, self.selected_alpha}, self.current_text_align, limit) inc = inc + 1
            self:printShadow(string.format("Screen Pos: (%i, %i)", screen_x, screen_y), x_offset, (32 * inc) + 10, {1, 1, 1, self.selected_alpha}, self.current_text_align, limit) inc = inc + 1

            if object.object_id then
                self:printShadow("World ID: " .. object.object_id,                      x_offset, (32 * inc) + 10, {1, 1, 1, self.selected_alpha}, self.current_text_align, limit) inc = inc + 1
            end

            local info = object:getDebugInfo()

            for i, line in ipairs(info) do
                self:printShadow(line, x_offset, (32 * inc) + 10, {1, 1, 1, self.selected_alpha}, self.current_text_align, limit)
                inc = inc + 1
            end
        end

        Object.endCache()
    else
        self.hover_alpha = 0
    end
    self.hover_alpha = Utils.clamp(self.hover_alpha, 0, 1)

    self:printShadow(header_name, 0, 16, COLORS.white, "center", 640)

    love.graphics.setColor(0, 1, 1, 1)

    -- Reset canvas to draw to
    Draw.setCanvas(SCREEN_CANVAS)

    love.graphics.setColor(1, 1, 1, menu_alpha)
    love.graphics.draw(self.menu_canvas, 0, 0)

    super:draw(self)
end

function DebugSystem:printShadow(text, x, y, color, align, limit)
    local color = color or {1, 1, 1, 1}
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.font)
    love.graphics.setColor({0, 0, 0, color[4]})
    love.graphics.printf(text, x + 2, y + 2, limit or self.font:getWidth(text), align or "left")

    -- Draw the main text
    love.graphics.setColor(color)
    love.graphics.printf(text, x, y, limit or self.font:getWidth(text), align or "left")
end


return DebugSystem