---@class MenuFileName : StateClass
---@overload fun() : MenuFileName
local MenuFileName, super = Class(StateClass)

function MenuFileName:init()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)

    self:registerEvent("draw", self.draw)
end

function MenuFileName:onEnter(menu, from)
    local mod = menu.selected_mod

    self.file_namer = FileNamer({
        name = mod.nameInput ~= "force" and Kristal.Config["defaultName"],
        limit = 12,

        mod = mod,
        white_fade = mod.whiteFade ~= false and not mod.transition,

        on_confirm = function(name)
            Kristal.loadMod(mod.id, menu.file_select.selected_y, name)

            if mod.transition then
                self.file_namer.name_preview.visible = false
                self.file_namer.text:setText("")
            elseif self.file_namer.do_fadeout then
                menu.fader:fadeOut{speed = 0.5, color = {0, 0, 0}}
            else
                menu.fader.fade_color = {0, 0, 0}
                menu.fader.alpha = 1
            end
        end,

        on_cancel = function()
            menu:setState("FILESELECT")
        end
    })
    self.file_namer.layer = 50

    menu.stage:addChild(self.file_namer)

    menu.heart.visible = false
end

function MenuFileName:onLeave(menu, next)
    self.file_namer:remove()
    self.file_namer = nil

    menu.heart.visible = true
end

function MenuFileName:draw(menu)
    local mod_name = string.upper(menu.selected_mod.name or menu.selected_mod.id)
    menu:printShadow(mod_name, 16, 8, {1, 1, 1, 1})
end

return MenuFileName