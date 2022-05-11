local ContextMenu, super = Class(Object)

function ContextMenu:init(name)
    super:init(self, 0, 0)
    self.layer = 10000000

    self.font_size = 16
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.name = name
    self.items = {}

    OVERLAY_OPEN = true
    Kristal.showCursor()

    self.grabbing = false
    self.grab_offset_x = 0
    self.grab_offset_y = 0

    self.anim_timer = 0

    self.canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    self.canvas:setFilter("nearest", "nearest")

    self.closing = false
end

function ContextMenu:close()
    if Kristal.DebugSystem.context == self then
        Kristal.DebugSystem.context = nil
    end
    self.closing = true
    self.anim_timer = 0.2
end

function ContextMenu:onMousePressed(x, y, button, istouch, presses)
    if not self:isMouseOver(0, 0, self.width, self.height) then
        self:close()
        return false
    end

    if button ~= 1 then return true end

    if not self.name then
        return true
    end

    local offset = self.font:getHeight(self.name) + 4 + self:getVerticalPadding() -- name has 4 extra pixels

    if self:isMouseOver(0, 0, self.width, offset) then
        self.grabbing = true
        self.grab_offset_x = x - self.x
        self.grab_offset_y = y - self.y
    end

    return true
end

function ContextMenu:onMouseReleased(x, y, button, istouch, presses)
    if button == 2 then return end
    if button == 1 and self.grabbing then
        self.grabbing = false
        return
    end

    local offset = self:getVerticalPadding()

    if self.name then
        offset = offset + self.font:getHeight(self.name) + 4 -- name has 4 extra pixels
    end

    for i, item in ipairs(self.items) do
        if self:isMouseOver(0, offset, self.width, offset + item.height) then
            if item.callback then
                item.callback()
            end
            if item.should_close then
                self:close()
            end
            return
        end
        offset = offset + item.height
    end

    self:close()
    return
end

function ContextMenu:addMenuItem(name, description, callback, options)
    options = options or {}
    local item = {
        name = name,
        description = description,
        callback = callback
    }
    item.width  = options["width" ] or self.font:getWidth(name)
    item.height = options["height"] or self.font:getHeight(name)
    item.should_close = options["should_close"] ~= false
    table.insert(self.items, item)
end

function ContextMenu:update()
    if self.closing then
        self.anim_timer = self.anim_timer - DT
        if self.anim_timer <= 0 then
            self:remove()
            return
        end
    else
        self.anim_timer = self.anim_timer + DT
    end
    local inner_width = self:getInnerWidth()
    local inner_height = self:getInnerHeight()

    self.width  = inner_width  + (self:getHorizontalPadding() * 2)
    self.height = inner_height + (self:getVerticalPadding()   * 2)

    self:setOrigin(0, 0)
    screen_x, screen_y = self:localToScreenPos(self.width, self.height)
    if screen_x > SCREEN_WIDTH then
        self.origin_x = 1
    end
    if screen_y > SCREEN_HEIGHT then
        self.origin_y = 1
    end

    if self.grabbing then
        local x, y = Input.getMousePosition()
        self.x = x - self.grab_offset_x
        self.y = y - self.grab_offset_y
    end

    super:update(self)
end

function ContextMenu:getHorizontalPadding()
    return 16
end

function ContextMenu:getVerticalPadding()
    return 2
end

function ContextMenu:getInnerWidth()
    local inner_width = self.font:getWidth(self.name or "")

    for i, item in ipairs(self.items) do
        inner_width = math.max(inner_width, self.font:getWidth(item.name or ""))
    end

    return inner_width
end

function ContextMenu:getInnerHeight()
    local height = 0
    if self.name then
        height = height + self.font:getHeight() + 4
    end

    for i, item in ipairs(self.items) do
        height = height + item.height
    end
    return height
end

function ContextMenu:getLocalMousePosition()
    return self:screenToLocalPos(Input.getMousePosition())
end

function ContextMenu:isMouseOver(x1, y1, x2, y2)
    local mouse_x, mouse_y = self:getLocalMousePosition()
    return mouse_x >= x1 and mouse_x < x2 and mouse_y >= y1 and mouse_y < y2
end

function ContextMenu:draw()
    local padding_x = self:getHorizontalPadding()
    local padding_y = self:getVerticalPadding()

    Draw.pushCanvas(self.canvas)
    love.graphics.clear()

    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)
    local offset = self:getVerticalPadding()
    local tooltip_to_draw = nil
    if self.name then
        offset = offset + self.font:getHeight() + 4 -- name has 4 extra pixels
        love.graphics.setColor(0.156863, 0.172549, 0.211765, 0.8)
        love.graphics.rectangle("fill", 0, 0, self.width, offset)
    
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self.name, padding_x, padding_y)
    
        love.graphics.setLineWidth(2)
        love.graphics.line(0, offset, self.width, offset)
    end

    for i, item in ipairs(self.items) do
        if self:isMouseOver(0, offset, self.width, offset + item.height) then
            love.graphics.setColor(1, 0.070588, 0.466667, 0.8)
            tooltip_to_draw = item
        else
            love.graphics.setColor(0.156863, 0.172549, 0.211765, 0.8)
        end
        love.graphics.rectangle("fill", 0, offset, self.width, item.height)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name or "", padding_x, padding_y + offset - 3)
        offset = offset + item.height
    end

    love.graphics.setColor(0.156863, 0.172549, 0.211765, 0.8)
    love.graphics.rectangle("fill", 0, offset, self.width, self.height - offset)

    if tooltip_to_draw then
        local mouse_x, mouse_y = self:getLocalMousePosition()
        local tooltip_x, tooltip_y = mouse_x, mouse_y
        tooltip_x = tooltip_x + 12
        local tooltip_padding_x, tooltip_padding_y = 2, 2
        local tooltip_width, tooltip_height = tooltip_padding_x * 2, tooltip_padding_y * 2

        tooltip_width  = tooltip_width  + self.font:getWidth (tooltip_to_draw.description)
        tooltip_height = tooltip_height + self.font:getHeight() * #Utils.split(tooltip_to_draw.description, "\n", false)

        love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_width, tooltip_height)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tooltip_to_draw.description, tooltip_x + tooltip_padding_x, tooltip_y + tooltip_padding_y - 2)
    end

    love.graphics.setColor(1, 1, 1, 1)

    -- Reset canvas to draw to
    Draw.popCanvas()

    local anim = Utils.ease(0, 1, self.anim_timer/0.2, "outQuad")
    love.graphics.setColor(1, 1, 1, anim)
    love.graphics.draw(self.canvas, 0, 12 - (anim * 12))

    super:draw(self)
end

return ContextMenu