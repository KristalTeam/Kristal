---@class ModCreateButton : Object
---@overload fun(...) : ModCreateButton
local ModCreateButton, super = Class(Object)

function ModCreateButton:init(width, height)
    super.init(self, 0, 0, width, height)

    self.name = "Create a new mod"
    self.subtitle = ""

    self.selected = false

    -- temporary
    self.font = Assets.getFont("main")
    self.subfont = Assets.getFont("main", 16)
end

function ModCreateButton:onSelect()
    self.selected = true
end

function ModCreateButton:onDeselect()
    self.selected = false
end

function ModCreateButton:getDrawColor()
    local r, g, b, a = 1, 1, 0.7, 1
    if not self.selected then
        return r * 0.6, g * 0.6, b * 0.7, a
    else
        return r, g, b, a
    end
end

function ModCreateButton:getHeartPos()
    return 29, self.height / 2
end

function ModCreateButton:getIconPos()
    return self.width + 8, 0
end

function ModCreateButton:update()
    super.update(self)
end

function ModCreateButton:draw()

    -- Draw the transparent backgrounds
    Draw.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Draw the rectangle outline
    Draw.setColor(self:getDrawColor())
    Draw.drawMenuRectangle(0, 0, self.width, self.height)

    -- Draw a plus at the heart position
    if not self.selected then
        local plus_x, plus_y = self:getHeartPos()
        local plus_tex = Assets.getTexture("kristal/menu_plus")
        Draw.setColor(self:getDrawColor())
        Draw.draw(plus_tex, plus_x - plus_tex:getWidth()/2, plus_y - plus_tex:getHeight()/2)
    end

    -- Draw text inside the button rectangle
    Draw.pushScissor()
    Draw.scissor(0, 0, self.width, self.height)

    -- Set name position
    local name_y = math.floor((self.height/2 - self.font:getHeight()/2) / 2) * 2
    love.graphics.setFont(self.font)
    -- Draw the name shadow
    Draw.setColor(0, 0, 0)
    love.graphics.print(self.name, 50 + 2, name_y + 2)
    -- Draw the name
    Draw.setColor(self:getDrawColor())
    love.graphics.print(self.name, 50, name_y)

    Draw.popScissor()

end

return ModCreateButton
