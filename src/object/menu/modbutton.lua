local ModButton, super = Class(Object)

function ModButton:init(name, width, height, mod)
    super:init(self, 0, 0, width, height)

    self.name = name
    self.mod = mod
    self.id = mod and mod.id or name

    self.selected = false

    -- temporary
    self.font = Assets.getFont("main")

    self.text = Text(self.name, 50, self.height/2 - ModMenuChar:getTextHeight()/2, ModMenuChar)
    self.text.inherit_color = true
    self:addChild(self.text)
end

function ModButton:setName(name)
    self.name = name
    self.text:setText(name)
end

function ModButton:onSelect()
    self.selected = true
    if self.preview_script and self.preview_script.onSelect then
        self.preview_script:onSelect(self)
    end
end

function ModButton:onDeselect()
    self.selected = false
    if self.preview_script and self.preview_script.onDeselect then
        self.preview_script:onDeselect(self)
    end
end

function ModButton:getDrawColor()
    local r, g, b, a = super:getDrawColor(self)
    if not self.selected then
        return r * 0.6, g * 0.6, b * 0.7, a
    else
        return r, g, b, a
    end
end

function ModButton:getHeartPos()
    return 29, self.height / 2
end

function ModButton:draw()
    -- Draw the transparent background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    love.graphics.setColor(self:getDrawColor())
    -- Draw the rectangles
    love.graphics.rectangle("line", 0, 0, self.width + 1, self.height + 1)
    -- Increase the width and height by one instead of two to produce the broken effect
    love.graphics.rectangle("line", -1, -1, self.width + 2, self.height + 2)
    love.graphics.rectangle("line", -2, -2, self.width + 5, self.height + 5)
    -- Here too
    love.graphics.rectangle("line", -3, -3, self.width + 6, self.height + 6)

    -- Draw children inside the current box
    Draw.pushScissor()
    Draw.scissor(0, 0, self.width, self.height)
    -- TODO: Non-monospaced fonts, for now we just draw it here
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.name, 50 + 2, math.floor((self.height/2 - self.font:getHeight()/2) / 2) * 2 + 2)
    love.graphics.setColor(self:getDrawColor())
    love.graphics.print(self.name, 50, math.floor((self.height/2 - self.font:getHeight()/2) / 2) * 2)
    --self:drawChildren()
    Draw.popScissor()
end

return ModButton