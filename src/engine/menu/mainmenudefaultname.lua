---@class MainMenuDefaultName : StateClass
---
---@field menu MainMenu
---
---@field file_namer FileNamer
---
---@overload fun(menu:MainMenu) : MainMenuDefaultName
local MainMenuDefaultName, super = Class(StateClass)

function MainMenuDefaultName:init(menu)
    self.menu = menu
end

function MainMenuDefaultName:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuDefaultName:onEnter(old_state)
    local mod = self.menu.selected_mod

    self.file_namer = FileNamer({
        name = Kristal.Config["defaultName"],
        limit = 12,
        start_confirm = true,

        mod = mod,

        on_confirm = function(name)
            Kristal.Config["defaultName"] = name
            self.menu:popState()
        end,

        on_cancel = function()
            Kristal.Config["defaultName"] = ""
            self.menu:popState()
        end
    })
    self.file_namer.layer = 50

    self.menu.stage:addChild(self.file_namer)

    self.menu.heart.visible = false
end

function MainMenuDefaultName:onLeave(new_state)
    self.file_namer:remove()
    self.file_namer = nil

    self.menu.heart.visible = true
end

return MainMenuDefaultName