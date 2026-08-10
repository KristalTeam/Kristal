---@class MainMenuAbout : StateClass
---
---@field menu MainMenu
---
---@field logo love.Image
---@field has_target_saves boolean
---
---@field options table
---@field selected_option number
---
---@overload fun(menu:MainMenu) : MainMenuAbout
local MainMenuAbout, super = Class(StateClass)

function MainMenuAbout:init(menu)
    self.menu = menu

    self.logo = Assets.getTexture("kristal/title_logo_shadow")

    self.selected_option = 1
end

function MainMenuAbout:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuAbout:onEnter(old_state)
    self.options = {
        { "website", "Website" },
        { "wiki", "Wiki" },
        { "github", "GitHub" },
        { "discord", "Discord" },
        { "reddit", "Reddit" },
        { "bluesky", "Bluesky" },
        { "back", "Back" },
    }

    self.selected_option = 1

    self.menu.heart_target_x = 252
    self.menu.heart_target_y = 238 + 16 + 32 * (self.selected_option - 1)
end

function MainMenuAbout:handleInput()
    if Input.pressed("cancel") then
        self.menu:setState("TITLE")
        self.menu.title_screen:selectOption("about")
        Assets.stopAndPlaySound("ui_move")
        return
    end

    if Input.pressed("confirm") then
        Assets.stopAndPlaySound("ui_select")

        local option = self.options[self.selected_option][1]

        if option == "website" then
            love.system.openURL("https://kristal.cc")
        elseif option == "wiki" then
            love.system.openURL("https://kristal.cc/wiki")
        elseif option == "github" then
            love.system.openURL("https://github.com/KristalTeam/Kristal")
        elseif option == "discord" then
            love.system.openURL("https://discord.gg/kristal")
        elseif option == "reddit" then
            love.system.openURL("https://reddit.com/r/kristal")
        elseif option == "bluesky" then
            love.system.openURL("https://bsky.app/profile/kristal.cc")
        elseif option == "back" then
            self.menu:setState("TITLE")
            self.menu.title_screen:selectOption("about")
        end
        return
    end

    local old_selected_option = self.selected_option

    if self.selected_option == 1 then
        if Input.pressed("up") then
            self.selected_option = #self.options
        end
    elseif Input.pressed("up", true) then
        self.selected_option = self.selected_option - 1
    end

    if self.selected_option == #self.options then
        if Input.pressed("down") then
            self.selected_option = 1
        end
    elseif Input.pressed("down", true) then
        self.selected_option = self.selected_option + 1
    end

    if old_selected_option ~= self.selected_option then
        Assets.stopAndPlaySound("ui_move")

        self.menu.heart_target_x = 252
        self.menu.heart_target_y = 238 + 16 + (self.selected_option - 1) * 32
    end
end

function MainMenuAbout:update()
    self:handleInput()
end

function MainMenuAbout:draw()

    local logo_height = self.logo:getHeight()
    local logo_position = 105 - 32 - logo_height / 2
    local love_color = {0.91764705882353, 0.1921568627451, 0.43137254901961}

    Draw.draw(self.logo, SCREEN_WIDTH / 2 - self.logo:getWidth() / 2, logo_position)

    Draw.printShadow({
        COLORS.white, "... is a ", COLORS.yellow, "DELTARUNE", COLORS.white, " fangame engine,\nusing the ", love_color, "LÖVE", COLORS.white, " game framework."
    }, 32, logo_position + logo_height + 16, nil, "center", 576)

    for i, option in ipairs(self.options) do
        Draw.printShadow(option[2], 271, 219 + 16 + 32 * (i - 1))
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuAbout:selectOption(id)
    for i, options in ipairs(self.options) do
        if options[1] == id then
            self.selected_option = i

            self.menu.heart_target_x = 229
            self.menu.heart_target_y = 238 + 16 + (self.selected_option - 1) * 32

            return true
        end
    end

    return false
end

return MainMenuAbout
