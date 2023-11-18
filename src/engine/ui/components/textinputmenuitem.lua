---@class TextInputMenuItemComponent : AbstractMenuItemComponent
---@field input table
---@field options table
---@overload fun(...) : TextInputMenuItemComponent
local TextInputMenuItemComponent, super = Class(AbstractMenuItemComponent)

---@param options? table
function TextInputMenuItemComponent:init(options)
    options = options or {}
    super.init(self, FillSizing(), FixedSizing(options.height or 32), nil, options)
    self.input = {options.starting or ""}
    self.options = options
end

function TextInputMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self:setFocused()

    TextInput.attachInput(self.input, self.options.input_settings or {
        enter_submits = true,
        multiline = false,
        clear_after_submit = false
    })
    TextInput.submit_callback = self.options.submit_callback or function()
        self:setUnfocused()
        TextInput.endInput()
        Input.clear("return")
        Assets.playSound("ui_select")
    end

    self.up_limit_callback = self.options.up_limit_callback or nil
    self.down_limit_callback = self.options.down_limit_callback or nil
    self.pressed_callback = self.options.pressed_callback or nil
    self.text_callback = self.options.text_callback or nil
end

function TextInputMenuItemComponent:draw()
    super.draw(self)

    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(0, self.height, self.width, self.height)

    local font = Assets.getFont(self.options.font or "main")

    if self:isFocused() then
        TextInput.draw({
            x = 0,
            y = 0,
            font = font,
            print = function(text, x, y) love.graphics.print(text, x, y) end,
        })
    else
        love.graphics.setFont(font)
        love.graphics.print(self.input[1], 0, 0)
    end
end

return TextInputMenuItemComponent
