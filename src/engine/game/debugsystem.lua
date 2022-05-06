local DebugSystem, super = Class(Object)

function DebugSystem:init()
    super:init(self, 0, 0)
    self.layer = 10000000 - 1

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
end

function DebugSystem:mouseOpen()
    return self.state == "MOUSE"
end

function DebugSystem:onMousePressed(x, y, button, istouch, presses)
    if button == 3 then
        if self:mouseOpen() then
            self:closeMouse()
        else
            self:openMouse()
        end
        return
    end

    if self:mouseOpen() then
        if button == 1 then
            local object = self:detectObject(Input.getMousePosition())

            if object then
                self:unselectObject()
                self.object = object
                self.last_object = object
                self.object:addFX(self.flash_fx)
                self.grabbing = true
                local screen_x, screen_y = object:getScreenPos()
                self.grab_offset_x = x - screen_x
                self.grab_offset_y = y - screen_y
            else
                self:unselectObject()
            end
        end
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
    if button == 1 then
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

    if Game.stage then
        local objects = Game.stage:getObjects()
        Object.startCache()
        for _,instance in ipairs(objects) do
            if instance:isDebugSelectable() and instance:isFullyVisible() then
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
    self:registerMenu("~ KRISTAL DEBUG ~", "main")
    self.current_menu = "main"
    self:registerDefaults()
    Kristal.callEvent("registerModDebugEntries")
    self:registerSubMenus()
    Kristal.callEvent("registerModDebugMenus")
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

function DebugSystem:registerMenu(name, id)
    self.menus[id] = {
        name = name,
        options = {}
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
end

function DebugSystem:registerSubMenus()
    self:registerMenu("Cutscene Select", "cutscene_select")
    -- loop through registry and add menu options for all cutscenes
    for group,cutscene in pairs(Registry.world_cutscenes) do
        if type(cutscene) == "table" then
            for id,_ in pairs(cutscene) do
                self:registerOption("cutscene_select", group.."."..id, "Start This Cutscene", function()
                    Game.world:startCutscene(group, id)
                    self:closeMenu()
                end)
            end
        else
            self:registerOption("cutscene_select", group, "Start This Cutscene", function()
                Game.world:startCutscene(group)
                self:closeMenu()
            end)
        end
    end
    self:registerOption("cutscene_select", "Back", "Go back to the previous menu.", function() self:returnMenu() end)
end

function DebugSystem:registerDefaults()
    -- Global
    self:registerConfigOption("main", "Show FPS", "Toggle the FPS display.", "showFPS")
    self:registerConfigOption("main", "VSync", "Toggle Vsync.", "vSync", function()
        love.window.setVSync(Kristal.Config["vSync"] and 1 or 0)
    end)
    self:registerConfigOption("main", "Object Selection Pausing", "Pauses the game when the object selection menu is opened.", "objectSelectionSlowdown")

    self:registerOption("main", "Print Performance", "Show performance in the console.", function() PERFORMANCE_TEST_STAGE = "UPDATE" end)

    self:registerOption("main", "Fast Forward", function() return self:appendBool("Speed up the engine.", FAST_FORWARD) end, function() FAST_FORWARD = not FAST_FORWARD end)
    self:registerOption("main", "Debug Rendering", function() return self:appendBool("Draw debug information.", DEBUG_RENDER) end, function() DEBUG_RENDER = not DEBUG_RENDER end)
    self:registerOption("main", "Hotswap", "Swap out code from the files. Might be unstable.", function() Hotswapper.scan() end)
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

    self:registerOption("main", "Refresh Menu", "Refresh this menu.", function() self:refresh() end)

    -- World specific
    self:registerOption("main", function()
        if Game.world.player then
            return "Remove The Player"
        else
            return "Spawn The Player"
        end
    end, "Spawn or remove the current player's object.", function()
        if Game.world.player then
            Game.world.player:explode()
        else
            Game.world:spawnPlayer(Game.world.camera.x, Game.world.camera.y, Game.party[1]:getActor())
            Game.world.player:interpolateFollowers()
        end
    end, "OVERWORLD")

    self:registerOption("main", "Play Cutscene", "Play a cutscene.", function()
        self:enterMenu("cutscene_select", 1)
    end, "OVERWORLD")

    -- Battle specific
    self:registerOption("main", "Leave Battle", "Instantly complete a battle.", function() Game.battle:setState("VICTORY") end, "BATTLE")
end

function DebugSystem:getValidOptions()
    local options = {}
    for i, v in ipairs(self.menus[self.current_menu].options) do
        if (Game and v.state == Game.state)
           or v.state == "ALL" then

            table.insert(options, v)
        end
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
        love.keyboard.setKeyRepeat(true) -- TODO: Text repeat stack
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
        love.keyboard.setKeyRepeat(false)
    end
end

function DebugSystem:updateBounds(options)
    if self.current_selecting <= 0 then self.current_selecting = #options end
    if self.current_selecting > #options then self.current_selecting = 1 end
    if self.state == "MENU" then
        self.heart_target_x = 19
        self.heart_target_y = (self.current_selecting - 1) * 32 + 35 + 32
    end
end

function DebugSystem:keypressed(key, _, is_repeat)
    if Input.is("object_selector", key) then
        if self:mouseOpen() then
            self:closeMouse()
        else
            self:openMouse()
        end
        return
    end
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
        if Input.is("down", key) and (not is_repeat or self.current_selecting < #options) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting + 1
        end
        if Input.is("up", key) and (not is_repeat or self.current_selecting > 1) then
            Assets.playSound("ui_move")
            self.current_selecting = self.current_selecting - 1
        end
        self:updateBounds(options)
    end
end

function DebugSystem:isMenuOpen()
    return self.state == "MENU"
end

function DebugSystem:update()
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2)then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT

    if self.object and self.object:isRemoved() then
        self:unselectObject()
    end

    -- Update grabbed object
    if self.grabbing then
        if self.object then
            local x, y = Input.getMousePosition()
            self.object:setScreenPos(x - self.grab_offset_x, y - self.grab_offset_y)
        end
    end

    self.menu_anim_timer = self.menu_anim_timer + DT / 0.5 -- 0.5 seconds
    self.circle_anim_timer = self.circle_anim_timer + DT / 0.5

    self.flash_fx:setColor(1, 1, 1)
    self.flash_fx.amount = -math.cos((love.timer.getTime() * 30) / 5) * 0.4 + 0.6

    if Game.stage then
        if self.state == "MOUSE" and Kristal.Config["objectSelectionSlowdown"] then
            Game.stage.timescale = math.max(Game.stage.timescale - (DT / 0.6), 0)
            if Game.stage.timescale == 0 then
                Game.stage.active = false
                Game.stage:updateAllLayers()
            end
        else
            Game.stage.timescale = math.min(Game.stage.timescale + (DT / 0.6), 1)
            Game.stage.active = true
        end
    end
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

    if self.state == "MENU" or (self.old_state == "MENU" and self.state == "IDLE") then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

        header_name = self.menus[self.current_menu].name

        local options = self:getValidOptions()
        for index, option in ipairs(options) do
            local name = option.name
            if type(name) == "function" then
                name = name()
            end
            self:printShadow(name, text_offset + 19, y_off + menu_y + (index - 1) * 32 + 16)
            if self.current_selecting == index then
                if option.description then
                    local description = option.description
                    if type(description) == "function" then
                        description = description()
                    end
                    local width, wrapped = self.font:getWrap(description, 580)
                    for i, line in ipairs(wrapped) do
                        self:printShadow(line, 0, 480 + (32 * i) - (32 * (#wrapped + 1)), COLORS.gray, "center", 640)
                    end
                end
            end
        end
    elseif self.state == "MOUSE" or (self.old_state == "MOUSE" and self.state == "IDLE") then
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
        if not self.grabbing then
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

            tooltip_x = tooltip_x + Utils.ease(0, 1, (1 - self.hover_alpha), "inCubic") * 10

            love.graphics.setFont(tooltip_font)
            love.graphics.setColor(0, 0, 0, self.hover_alpha)
            love.graphics.print(tooltip_text, tooltip_x-1, tooltip_y)
            love.graphics.print(tooltip_text, tooltip_x+1, tooltip_y)
            love.graphics.print(tooltip_text, tooltip_x, tooltip_y-1)
            love.graphics.print(tooltip_text, tooltip_x, tooltip_y+1)
            love.graphics.setColor(1, 1, 1, self.hover_alpha)
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

            local info = object:getDebugInformation()

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