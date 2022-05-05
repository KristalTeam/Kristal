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

    -- States: IDLE, MENU, SUBMENU
    self.state = "IDLE"
    self.state_reason = nil

    self.current_selecting = 1

    self.current_subselecting = 1

    self.menu_canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    self.menu_canvas:setFilter("nearest", "nearest")

    self.menus = {}

    self:refresh()

    self.current_menu = "main"

    self.menu_anim_timer = 1

    self.menu_history = {}

    self.object = nil
end

function DebugSystem:onMousePressed(x, y, button, istouch, presses)
    local object = self:detectObject(Input.getMousePosition())

    if object then
        self.object = object
        local recolor = self.object:addFX(RecolorFX())
        recolor.color = {0, 1, 0}
    end
end

function DebugSystem:detectObject(x, y)
    local hierarchy_size = -1
    local found = false
    local object = nil

    if Game.stage then
        local objects = Game.stage:getObjects()
        Object.startCache()
        for _,instance in ipairs(objects) do
            local mx, my = instance:getFullTransform():inverseTransformPoint(x, y)
            if mx > 0 and mx < instance.width and my > 0 and my < instance.height then
                if #instance:getHierarchy() > hierarchy_size then
                    hierarchy_size = #instance:getHierarchy()
                    object = instance
                    found = true
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

function DebugSystem:openMenu()
    self.menu_anim_timer = 0
    OVERLAY_OPEN = true
    Assets.playSound("ui_select")
    self:setState("MENU")
    Kristal.showCursor()
    love.keyboard.setKeyRepeat(true) -- TODO: Text repeat stack
end

function DebugSystem:closeMenu()
    self.menu_anim_timer = 0
    OVERLAY_OPEN = false
    self:setState("IDLE")
    Kristal.hideCursor()
    love.keyboard.setKeyRepeat(false)
end

function DebugSystem:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

function DebugSystem:onStateChange(old, new)
    self.heart_target_x = -10
    if new == "MENU" then
        self.heart_target_x = 19
        self.heart_target_y = 35 + 32
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

    self.menu_anim_timer = self.menu_anim_timer + DT / 0.5 -- 0.5 seconds
end

function DebugSystem:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)

    local menu_x = 0
    local menu_y = 0
    local menu_alpha = 0


    if self.state == "MENU" then
        menu_y = Utils.ease(-32, 0, self.menu_anim_timer, "outExpo")
        menu_alpha = Utils.ease(0, 1, self.menu_anim_timer, "outExpo")
    else
        menu_y = Utils.ease(0, -32, self.menu_anim_timer, "outExpo")
        menu_alpha = Utils.ease(1, 0, self.menu_anim_timer, "outExpo")
    end

    love.graphics.setColor(0, 0, 0, 0.5)

    local text_offset = menu_x + 19
    local y_off = 32

    Draw.setCanvas(self.menu_canvas)
    love.graphics.clear()

    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self:printShadow(self.menus[self.current_menu].name, 0, 16, COLORS.white, "center", 640)

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

    love.graphics.setColor(0, 1, 1, 1)
    local object = self:detectObject(Input.getMousePosition())

    if object then
        local x, y = object:localToScreenPos(0, 0)
        local x2, y2 = object:localToScreenPos(object.width, object.height)
        love.graphics.rectangle("line", x, y, x2 - x, y2 - y)
    end


    -- Reset canvas to draw to
    Draw.setCanvas(SCREEN_CANVAS)

    love.graphics.setColor(1, 1, 1, menu_alpha)
    love.graphics.draw(self.menu_canvas, 0, 0)

    super:draw(self)
end

function DebugSystem:printShadow(text, x, y, color, align, limit)
    -- Draw the shadow, offset by two pixels to the bottom right
    love.graphics.setFont(self.font)
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(text, x + 2, y + 2, limit or self.font:getWidth(text), align or "left")

    -- Draw the main text
    love.graphics.setColor(color or {1, 1, 1, 1})
    love.graphics.printf(text, x, y, limit or self.font:getWidth(text), align or "left")
end


return DebugSystem