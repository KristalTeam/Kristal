--- The border option for the [`DarkConfigMenu`](lua://DarkConfigMenu).
---
---@class DarkConfigBorderOption : DarkConfigOption
---@overload fun(...) : DarkConfigBorderOption
local DarkConfigBorderOption, super = Class(DarkConfigOption)

function DarkConfigBorderOption:init(menu)
    super.init(self, menu, "Border")

    self.selected = false
end

function DarkConfigBorderOption:onStateChanged(old, new)
    super.onStateChanged(self, old, new)

    if old == "BORDERS" then
        self.text:setColor(PALETTE["world_text"])
        self.selected = false
    end
end

function DarkConfigBorderOption:onSelected()
    super.onSelected(self)

    self.menu:setState("BORDERS")
    self.text:setColor(PALETTE["world_text_selected"])
    self.selected = true
end

function DarkConfigBorderOption:draw()
    super.draw(self)

    if self.selected then
        Draw.setColor(PALETTE["world_text_selected"])
    else
        Draw.setColor(PALETTE["world_text"])
    end

    love.graphics.setFont(Assets.getFont("main"))

    love.graphics.print(Kristal.getBorderName(), 348, 0)
end

return DarkConfigBorderOption
