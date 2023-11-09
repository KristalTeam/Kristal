---@class BoxComponent : Component
---@overload fun(...) : BoxComponent
local BoxComponent, super = Class(Component)

function BoxComponent:init(x, y, x_sizing, y_sizing, skin)
    super.init(self, x, y, x_sizing, y_sizing)

    self:setMargins(40)

    self.box = UIBox(0, 0, 0, 0, skin)
    self.box.layer = -1
    self:addChild(self.box)
end

function BoxComponent:update()
    super.update(self)

    self.box.width = self.width
    self.box.height = self.height
end

function BoxComponent:getComponents()
    -- the box shouldn't be considered a child component, despite still being a child
    local components = {}
    for _, child in ipairs(super.getComponents(self)) do
        if child ~= self.box then
            table.insert(components, child)
        end
    end
    return components
end

return BoxComponent
