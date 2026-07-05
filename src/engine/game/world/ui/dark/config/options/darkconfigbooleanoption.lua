--- A boolean option for the [`DarkConfigMenu`](lua://DarkConfigMenu).
---
---@class DarkConfigBooleanOption : DarkConfigOption
---@overload fun(...) : DarkConfigBooleanOption
local DarkConfigBooleanOption, super = Class(DarkConfigOption)

function DarkConfigBooleanOption:init(menu, name, callback, default_value)
    super.init(self, menu, name, callback)

    self.enabled = default_value
end

function DarkConfigBooleanOption:setEnabled(enabled)
    self.enabled = enabled
end

function DarkConfigBooleanOption:draw()
    super.draw(self)

    Draw.setColor(PALETTE["world_text"])
    love.graphics.setFont(Assets.getFont("main"))
    love.graphics.print(self.enabled and "ON" or "OFF", 348, 0)
end

return DarkConfigBooleanOption
