---@class ContextMenu : Object
---@overload fun(...) : ContextMenu
local ContextMenu, super = Class(Object)

function ContextMenu:init(name)
    super.init(self, 0, 0)
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

    self.closing = false

    self.adjusted = false
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

function ContextMenu:getScreenBounds()
    local x, y = self:localToScreenPos(0, 0)
    local x2, y2 = self:localToScreenPos(self.width, self.height)
    return x, y, x2, y2
end

function ContextMenu:adjustToCorner()
    self:calculateSize()
    local screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    local mouse_x, mouse_y = Input.getMousePosition()
    if screen_right > SCREEN_WIDTH then
        self:setScreenPos(mouse_x - (screen_right - screen_left), screen_top)
        screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    end
    if screen_bottom > SCREEN_HEIGHT then
        self:setScreenPos(screen_left, mouse_y - (screen_bottom - screen_top))
    end
end

function ContextMenu:addMenuItem(name, description, callback, options)
    options           = options or {}
    local item        = {
        name = name,
        description = description,
        callback = callback
    }
    item.width        = options["width"] or self.font:getWidth(name)
    item.height       = options["height"] or self.font:getHeight(name)
    item.should_close = options["should_close"] ~= false
    table.insert(self.items, item)
end

function ContextMenu:calculateSize()
    self.width  = self:getInnerWidth() + (self:getHorizontalPadding() * 2)
    self.height = self:getInnerHeight() + (self:getVerticalPadding() * 2)
end

function ContextMenu:keepInBounds()
    local screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()

    if screen_left < 0 then
        self:setScreenPos(0, screen_top)
        screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    end
    if screen_right > SCREEN_WIDTH then
        self:setScreenPos(SCREEN_WIDTH - (screen_right - screen_left), screen_top)
        screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    end

    if screen_top < 0 then
        self:setScreenPos(screen_left, 0)
        screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    end
    if screen_bottom > SCREEN_HEIGHT then
        self:setScreenPos(screen_left, SCREEN_HEIGHT - (screen_bottom - screen_top))
        screen_left, screen_top, screen_right, screen_bottom = self:getScreenBounds()
    end
end

function ContextMenu:update()
    if self.closing then
        self.anim_timer = self.anim_timer - DT
        if self.anim_timer <= 0 then
            self:remove()
            Kristal.DebugSystem.last_context = nil
            return
        end
    else
        self.anim_timer = self.anim_timer + DT
    end

    local mouse_x, mouse_y = Input.getMousePosition()
    if self.grabbing then
        self.x = mouse_x - self.grab_offset_x
        self.y = mouse_y - self.grab_offset_y
    end

    self:calculateSize()

    if self.adjusted then
        self:keepInBounds()
    else
        self.adjusted = false
        self:adjustToCorner()
    end

    super.update(self)
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
    local bg_color = { 0.156863, 0.172549, 0.211765, 0.8 }
    local highlighted_color = { 1, 0.070588, 0.466667, 0.8 }

    if self.adjusted then
        self:keepInBounds()
    else
        self.adjusted = false
        self:adjustToCorner()
    end

    local padding_x = self:getHorizontalPadding()
    local padding_y = self:getVerticalPadding()

    local canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.clear()

    love.graphics.setFont(self.font)
    Draw.setColor(1, 1, 1, 1)
    local offset = self:getVerticalPadding()
    local tooltip_to_draw = nil
    if self.name then
        offset = offset + self.font:getHeight() + 4 -- name has 4 extra pixels
        Draw.setColor(bg_color)
        love.graphics.rectangle("fill", 0, 0, self.width, offset)

        Draw.setColor(1, 1, 1, 1)
        love.graphics.print(self.name, padding_x, padding_y)

        love.graphics.setLineWidth(2)
        love.graphics.line(0, offset, self.width, offset)
    end

    for i, item in ipairs(self.items) do
        if self:isMouseOver(0, offset, self.width, offset + item.height) then
            Draw.setColor(highlighted_color)
            tooltip_to_draw = item
        else
            Draw.setColor(bg_color)
        end
        love.graphics.rectangle("fill", 0, offset, self.width, item.height)

        Draw.setColor(1, 1, 1, 1)
        love.graphics.print(item.name or "", padding_x, padding_y + offset - 3)
        offset = offset + item.height
    end

    Draw.setColor(bg_color)
    love.graphics.rectangle("fill", 0, offset, self.width, self.height - offset)

    Draw.setColor(1, 1, 1, 1)

    -- Reset canvas to draw to
    Draw.popCanvas()

    local anim = Utils.ease(0, 1, self.anim_timer / 0.2, "outQuad")
    Draw.setColor(1, 1, 1, anim)
    Draw.draw(canvas, 0, 12 - (anim * 12))

    if tooltip_to_draw then
        local mouse_x, mouse_y                     = self:getLocalMousePosition()
        local tooltip_x, tooltip_y                 = mouse_x, mouse_y
        tooltip_x                                  = tooltip_x + 12
        local tooltip_padding_x, tooltip_padding_y = 2, 2
        local tooltip_width, tooltip_height        = tooltip_padding_x * 2, tooltip_padding_y * 2

        tooltip_width                              = tooltip_width + self.font:getWidth(tooltip_to_draw.description)
        tooltip_height                             = tooltip_height +
            self.font:getHeight() * #Utils.split(tooltip_to_draw.description, "\n", false)

        if tooltip_x + tooltip_width > self:screenToLocalPos(SCREEN_WIDTH, SCREEN_HEIGHT) then
            tooltip_x = mouse_x - tooltip_width - 4
        end

        local tooltip = Draw.pushCanvas(tooltip_width, tooltip_height)
        love.graphics.clear()
        Draw.setColor(bg_color)

        love.graphics.rectangle("fill", 0, 0, tooltip_width, tooltip_height)

        Draw.setColor(1, 1, 1, 1)
        love.graphics.print(tooltip_to_draw.description, tooltip_padding_x, tooltip_padding_y - 2)

        Draw.popCanvas()
        Draw.setColor(1, 1, 1, anim)
        Draw.draw(tooltip, tooltip_x + (12 - (anim * 12)), tooltip_y)
    end

    super.draw(self)
end

return ContextMenu
