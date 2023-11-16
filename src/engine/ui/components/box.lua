---@class BoxComponent : Component
---@field box UIBox
---@overload fun(...) : BoxComponent
local BoxComponent, super = Class(Component)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function BoxComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    options = options or {}
    self.box = UIBox(0, 0, 0, 0, options.skin)
    self.box.layer = -1
    self:addChild(self.box)
    self:setPadding(self.box:getBorder())
end

function BoxComponent:update()
    super.update(self)

    local border_width, border_height = self.box:getBorder()

    self.box.x = border_width
    self.box.y = border_height
    self.box.width = self.width - border_width * 2
    self.box.height = self.height - border_height * 2
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
