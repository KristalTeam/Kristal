---@class DarkConfigVolumeState : StateClass
---
---@field menu DarkConfigMenu
---
---@overload fun(menu: DarkConfigMenu) : DarkConfigVolumeState
local DarkConfigVolumeState, super = Class(StateClass)

function DarkConfigVolumeState:init(menu)
    self.menu = menu
end

function DarkConfigVolumeState:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.onUpdate)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function DarkConfigVolumeState:onEnter(old_state)
    self.noise_timer = 0
end

function DarkConfigVolumeState:onUpdate()
    if Input.pressed("cancel") or Input.pressed("confirm") then
        Kristal.setVolume(MathUtils.round(Kristal.getVolume() * 100) / 100)

        Kristal.saveConfig()
        
        Assets.stopAndPlaySound("ui_select")

        self.menu:setState("MAIN")
        return
    end

    self.noise_timer = self.noise_timer + DTMULT
    if Input.down("left") then
        Kristal.setVolume(Kristal.getVolume() - ((2 * DTMULT) / 100))
        if self.noise_timer >= 3 then
            self.noise_timer = self.noise_timer - 3
            Assets.stopAndPlaySound("noise")
        end
    end

    if Input.down("right") then
        Kristal.setVolume(Kristal.getVolume() + ((2 * DTMULT) / 100))
        if self.noise_timer >= 3 then
            self.noise_timer = self.noise_timer - 3
            Assets.stopAndPlaySound("noise")
        end
    end

    if (not Input.down("right")) and (not Input.down("left")) then
        self.noise_timer = 3
    end
end

return DarkConfigVolumeState
