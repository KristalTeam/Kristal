--- The volume option for the [`DarkConfigMenu`](lua://DarkConfigMenu).
---
---@class DarkConfigVolumeOption : DarkConfigOption
---@overload fun(...) : DarkConfigVolumeOption
local DarkConfigVolumeOption, super = Class(DarkConfigOption)

function DarkConfigVolumeOption:init(menu)
    super.init(self, menu, "Master Volume")

    self.selected = false
end

function DarkConfigVolumeOption:onStateChanged(old, new)
    super.onStateChanged(self, old, new)

    if old == "VOLUME" then
        self.text:setColor(PALETTE["world_text"])
        self.selected = false
    end
end

function DarkConfigVolumeOption:onSelected()
    super.onSelected(self)

    self.menu:setState("VOLUME")
    self.text:setColor(PALETTE["world_text_selected"])
    self.selected = true
end

function DarkConfigVolumeOption:draw()
    super.draw(self)

    if self.selected then
        Draw.setColor(PALETTE["world_text_selected"])
    else
        Draw.setColor(PALETTE["world_text"])
    end

    love.graphics.setFont(Assets.getFont("main"))

    love.graphics.print(MathUtils.round(Kristal.getVolume() * 100) .. "%", 348, 0)
end

return DarkConfigVolumeOption
