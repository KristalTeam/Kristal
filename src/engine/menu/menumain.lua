---@class MenuMain : StateClass
---
---@field menu Menu
---
---@overload fun(menu:Menu) : MenuMain
local MenuMain, super = Class(StateClass)

function MenuMain:init(menu)
    self.menu = menu

    self.logo = Assets.getTexture("kristal/title_logo_shadow")

    self.selected_option = 1
end

function MenuMain:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MenuMain:onEnter(old_state)
    if TARGET_MOD then
        self.options = {
            {"play",    self.menu.has_target_saves and "Load game" or "Start game"},
            {"options", "Options"},
            {"credits", "Credits"},
            {"quit",    "Quit"},
        }
    else
        self.options = {
            {"play",      "Play a mod"},
            {"modfolder", "Open mods folder"},
            {"options",   "Options"},
            {"credits",   "Credits"},
            {"quit",      "Quit"},
        }
    end

    self.menu.heart_target_x = 196
    self.menu.heart_target_y = 238 + 32 * (self.selected_option - 1)
end

function MenuMain:onLeave(new_state)
end

function MenuMain:onKeyPressed(key, is_repeat)
    if Input.isConfirm(key) then
        Assets.stopAndPlaySound("ui_select")

        local option = self.options[self.selected_option][1]

        if option == "play" then
            if not TARGET_MOD then
                self.menu:setState("MODSELECT")
            elseif self.menu.has_target_saves then
                self.menu:setState("FILESELECT")
            else
                Kristal.loadMod(TARGET_MOD, 1)
            end

        elseif option == "modfolder" then
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")

        elseif option == "options" then
            self.menu.heart_target_x = 152
            self.menu.heart_target_y = 129
            self.menu.selected_option = 1 -- TODO: Remove
            self.menu:setState("OPTIONS")

        elseif option == "credits" then
            self.menu:setState("CREDITS")

        elseif option == "quit" then
            love.event.quit()
        end

        return true
    end

    local old = self.selected_option
    if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1 end
    if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1 end
    if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1 end
    if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1 end
    if self.selected_option > #self.options then self.selected_option = is_repeat and #self.options or 1 end
    if self.selected_option < 1             then self.selected_option = is_repeat and 1 or #self.options end

    if old ~= self.selected_option then
        Assets.stopAndPlaySound("ui_move")
    end

    self.menu.heart_target_x = 196
    self.menu.heart_target_y = 238 + (self.selected_option - 1) * 32
end

function MenuMain:draw()
    local logo_img = self.menu.selected_mod and self.menu.selected_mod.logo or self.logo

    Draw.draw(logo_img, SCREEN_WIDTH/2 - logo_img:getWidth()/2, 105 - logo_img:getHeight()/2)
    --Draw.draw(self.selected_mod and self.selected_mod.logo or self.logo, 160, 70)

    for i, option in ipairs(self.options) do
        Draw.printShadow(option[2], 215, 219 + 32 * (i - 1))
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MenuMain:selectOption(id)
    for i, options in ipairs(self.options) do
        if options[1] == id then
            self.selected_option = i

            self.menu.heart_target_x = 196
            self.menu.heart_target_y = 238 + (self.selected_option - 1) * 32

            return true
        end
    end

    return false
end

return MenuMain