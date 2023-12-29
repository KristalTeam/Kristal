---@class MainMenuFileName : StateClass
---
---@field menu MainMenu
---
---@field file_namer FileNamer
---
---@overload fun(menu:MainMenu) : MainMenuFileName
local MainMenuFileName, super = Class(StateClass)

function MainMenuFileName:init(menu)
    self.menu = menu
end

function MainMenuFileName:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuFileName:onEnter(old_state)
    local mod = self.menu.selected_mod

    self.file_namer = FileNamer({
        name = mod.nameInput ~= "force" and string.sub(Kristal.Config["defaultName"], 1, mod["nameLimit"] or 12),
        limit = mod["nameLimit"] or 12,

        mod = mod,
        white_fade = mod.whiteFade ~= false and not mod.transition,

        on_confirm = function(name)
            Kristal.loadMod(mod.id, self.menu.file_select.selected_y, name)

            if mod.transition then
                self.file_namer.name_preview.visible = false
                self.file_namer.text:setText("")
            elseif self.file_namer.do_fadeout then
                self.menu.fader:fadeOut{speed = 0.5, color = {0, 0, 0}}
            else
                self.menu.fader.fade_color = {0, 0, 0}
                self.menu.fader.alpha = 1
            end
        end,

        on_cancel = function()
            self.menu:setState("FILESELECT")
        end
    })
    self.file_namer.layer = 50

    self.menu.stage:addChild(self.file_namer)

    self.menu.heart.visible = false
end

function MainMenuFileName:onLeave(new_state)
    self.file_namer:remove()
    self.file_namer = nil

    self.menu.heart.visible = true
end

function MainMenuFileName:draw()
    local mod_name = string.upper(self.menu.selected_mod.name or self.menu.selected_mod.id)
    Draw.printShadow(mod_name, 16, 8)
end

return MainMenuFileName
