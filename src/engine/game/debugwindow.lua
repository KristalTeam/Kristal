---@class DebugWindow : Object
---@overload fun(...) : DebugWindow
local DebugWindow, super = Class(Object)

function DebugWindow:init(name, text, type, callback)
    super.init(self, 0, 0)
    self.layer = 10000000 + 1

    -- VERY hardcoded object to handle message boxes used for debug purposes.
    -- "type" can be "input" currently, which has a text field.
    -- this type has two buttons being Cancel and OK.
    -- currently, button 1 will ALWAYS cancel, and any other button will act as OK.
    -- "callback" is a function that will be called when the OK button is pressed.
    -- name is the title of the message box. It has a default of "Message Box".
    -- text is the message that will be displayed in the box, and does NOT have a default.
    -- The dimensions of the box are hardcoded.

    self.font_size = 16
    self.font_name = "main"

    self.font = Assets.getFont(self.font_name, self.font_size)

    self.name = name or "Message Box"
    self.text = text
    self.type = type
    self.callback = callback

    self.buttons = {}

    self.input_lines = { "" }

    if self.type == "input" then
        self.buttons = { "Cancel", "OK" }
    end

    OVERLAY_OPEN = true
    Kristal.showCursor()

    self.grabbing = false
    self.grab_offset_x = 0
    self.grab_offset_y = 0

    self.anim_timer = 0

    self.closing = false


    if self.type == "input" then
        TextInput.attachInput(self.input_lines, {
            multiline = false,
            enter_submits = true,
        })
        TextInput.submit_callback = function (...) self:onSubmit() end
    end
end

function DebugWindow:close()
    TextInput.endInput()
    if Kristal.DebugSystem.window == self then
        Kristal.DebugSystem.window = nil
    end
    self.closing = true
    self.anim_timer = 0.2
end

function DebugWindow:onMousePressed(x, y, button, istouch, presses)
    local offset = self.font:getHeight(self.name) + 4 + self:getVerticalPadding() -- name has 4 extra pixels

    if self:isMouseOver(0, 0, self.width, offset) then
        self.grabbing = true
        self.grab_offset_x = x - self.x
        self.grab_offset_y = y - self.y
    end

    return
end

function DebugWindow:onMouseReleased(x, y, button, istouch, presses)
    if button == 2 then return end
    if button == 1 and self.grabbing then
        self.grabbing = false
        return
    end

    local padding_x = self:getHorizontalPadding()
    local padding_y = self:getVerticalPadding()
    local offset = self:getVerticalPadding()
    offset = offset + self.font:getHeight() + 4 -- name has 4 extra pixels
    -- Draw our text if we have any
    if self.text then
        offset = offset + (self.font:getHeight() * #Utils.split(self.text, "\n", false)) + 8
    end

    if self.type == "input" then
        offset = offset + 20 + 8
    end

    if #self.buttons > 0 then
        local button_off = 0
        for i = #self.buttons, 1, -1 do
            local button = self.buttons[i]
            local width = self.font:getWidth(button) + 20
            local x = self.width - 20 - width - button_off
            button_off = button_off + width + 20
            if self:isMouseOver(x, offset, x + width, offset + 20) then
                if i == 1 then -- cancel
                    self:close()
                    return
                end
                self:onSubmit()
            end
        end
    end
end

function DebugWindow:getScreenBounds()
    local x, y = self:localToScreenPos(0, 0)
    local x2, y2 = self:localToScreenPos(self.width, self.height)
    return x, y, x2, y2
end

function DebugWindow:calculateSize()
    self.width  = 320
    self.height = 120
end

function DebugWindow:keepInBounds()
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

function DebugWindow:update()
    if self.closing then
        self.anim_timer = self.anim_timer - DT
        if self.anim_timer <= 0 then
            self:remove()
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
    self:keepInBounds()

    super.update(self)
end

function DebugWindow:getLocalMousePosition()
    return self:screenToLocalPos(Input.getMousePosition())
end

function DebugWindow:isMouseOver(x1, y1, x2, y2)
    local mouse_x, mouse_y = self:getLocalMousePosition()
    return mouse_x >= x1 and mouse_x < x2 and mouse_y >= y1 and mouse_y < y2
end

function DebugWindow:getHorizontalPadding()
    return 16
end

function DebugWindow:getVerticalPadding()
    return 2
end

function DebugWindow:onSubmit()
    if self.callback then
        self.callback(self.input_lines[1])
    end
    self:close()
end

function DebugWindow:draw()
    local bg_color = { 0.156863, 0.172549, 0.211765, 0.8 }
    local highlighted_color = { 1, 0.070588, 0.466667, 0.8 }

    self:keepInBounds()

    local padding_x = self:getHorizontalPadding()
    local padding_y = self:getVerticalPadding()

    local canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.clear()

    love.graphics.setFont(self.font)
    Draw.setColor(1, 1, 1, 1)
    local offset = self:getVerticalPadding()
    local tooltip_to_draw = nil

    offset = offset + self.font:getHeight() + 4 -- name has 4 extra pixels
    Draw.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Draw the window name
    Draw.setColor(1, 1, 1, 1)
    love.graphics.print(self.name, padding_x, padding_y)

    -- Draw the window name line
    love.graphics.setLineWidth(2)
    love.graphics.line(0, offset, self.width, offset)

    -- Draw our text if we have any
    if self.text then
        love.graphics.print(self.text, padding_x, offset + 2)
        offset = offset + (self.font:getHeight() * #Utils.split(self.text, "\n", false)) + 8
    end

    love.graphics.setLineWidth(1)
    if self.type == "input" then
        Draw.setColor(bg_color)
        love.graphics.rectangle("fill", padding_x, offset, self.width - (padding_x * 2), 20)

        TextInput.draw({
            x = padding_x + 4,
            y = offset,
            font = self.font
        })

        offset = offset + 20 + 8

        Draw.setColor(1, 1, 1, 1)
        love.graphics.line(padding_x, offset - 8, self.width - padding_x, offset - 8)
    end

    if #self.buttons > 0 then
        -- loop through buttons in reverse
        local button_off = 0
        for i = #self.buttons, 1, -1 do
            local button = self.buttons[i]

            local width = self.font:getWidth(button) + 20

            local x = self.width - 20 - width - button_off

            button_off = button_off + width + 20

            if self:isMouseOver(x, offset, x + width, offset + 20) then
                Draw.setColor(highlighted_color)
            else
                Draw.setColor(bg_color)
            end

            love.graphics.rectangle("fill", x, offset, width, 20, 5, 5)
            Draw.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", x, offset, width, 20, 5, 5)

            love.graphics.print(button, x + 10, offset + 1)
        end
    end

    Draw.setColor(1, 1, 1, 1)

    Draw.popCanvas()

    local anim = Utils.ease(0, 1, self.anim_timer / 0.2, "outQuad")
    Draw.setColor(1, 1, 1, anim)
    Draw.draw(canvas, 0, 12 - (anim * 12))

    super.draw(self)
end

return DebugWindow
