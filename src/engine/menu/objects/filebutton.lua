---@class FileButton : Object
---@overload fun(...) : FileButton
local FileButton, super = Class(Object)

function FileButton:init(list, id, data, x, y, width, height)
    super.init(self, x, y, width, height)

    self.list = list
    self.data = data
    self.id = id or 1

    self:setData(data)

    self.selected = false

    self.font = Assets.getFont("main")
    self.subfont = Assets.getFont("main", 16)

    self.prompt = nil
    self.choices = nil
    self.selected_choice = 1
end

function FileButton:setData(data)
    self.data = data

    self.name = data and data.name or "[EMPTY]"
    self.area = data and data.room_name or "------------"

    if data and data.playtime then
        local minutes = math.floor(data.playtime / 60)
        local seconds = math.floor(data.playtime % 60)
        self.time = string.format("%d:%02d", minutes, seconds)
    else
        self.time = "--:--"
    end
end

function FileButton:setChoices(choices, prompt)
    self.prompt = prompt
    self.choices = choices
    self.selected_choice = 1
end

function FileButton:getDrawColor()
    local r, g, b, a = super.getDrawColor(self)
    if not self.selected then
        return r * 0.6, g * 0.6, b * 0.7, a
    else
        return r, g, b, a
    end
end

function FileButton:getHeartPos()
    if not self.choices then
        return 20, self.height / 2 - 9
    else
        if self.selected_choice == 1 then
            return 40, 52
        else
            return 220, 52
        end
    end
end

function FileButton:drawCoolRectangle(x, y, w, h)
    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    Draw.setColor(self:getDrawColor())
    -- Draw the rectangles
    love.graphics.rectangle("line", x, y, w + 1, h + 1)
    -- Increase the width and height by one instead of two to produce the broken effect
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2)
    love.graphics.rectangle("line", x - 2, y - 2, w + 5, h + 5)
    -- Here too
    love.graphics.rectangle("line", x - 3, y - 3, w + 6, h + 6)
end

function FileButton:draw()
    -- Draw the transparent background
    Draw.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Draw the rectangle outline
    self:drawCoolRectangle(0, 0, self.width, self.height)

    -- Draw text inside the button rectangle
    Draw.pushScissor()
    Draw.scissor(0, 0, self.width, self.height)

    if not self.prompt then
        -- Draw the name shadow
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.name, 50 + 2, 10 + 2)
        -- Draw the name
        Draw.setColor(self:getDrawColor())
        love.graphics.print(self.name, 50, 10)

        -- Draw the time shadow
        local time_x = self.width-64-self.font:getWidth(self.time)
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.time, time_x + 2, 10 + 2)
        -- Draw the time
        Draw.setColor(self:getDrawColor())
        love.graphics.print(self.time, time_x, 10)
    else
        -- Draw the prompt shadow
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.prompt, 50 + 2, 10 + 2)
        -- Draw the prompt
        Draw.setColor(self:getDrawColor())
        love.graphics.print(self.prompt, 50, 10)
    end

    if not self.choices then
        -- Draw the area shadow
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.area, 50 + 2, 44 + 2)
        -- Draw the area
        Draw.setColor(self:getDrawColor())
        love.graphics.print(self.area, 50, 44)
    else
        -- Draw the shadow for choice 1
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.choices[1], 70+2, 44+2)
        -- Draw choice 1
        if self.selected_choice == 1 then
            Draw.setColor(1, 1, 1)
        else
            Draw.setColor(0.6, 0.6, 0.7)
        end
        love.graphics.print(self.choices[1], 70, 44)

        -- Draw the shadow for choice 2
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.choices[2], 250+2, 44+2)
        -- Draw choice 2
        if self.selected_choice == 2 then
            Draw.setColor(1, 1, 1)
        else
            Draw.setColor(0.6, 0.6, 0.7)
        end
        love.graphics.print(self.choices[2], 250, 44)
    end

    Draw.popScissor()
end

return FileButton