---@class ListMenuItemComponent : AbstractMenuItemComponent
---@overload fun(...) : ListMenuItemComponent
local ListMenuItemComponent, super = Class(AbstractMenuItemComponent)

function ListMenuItemComponent:init(list, value, on_changed, options)
    super.init(self, 0, 0, FitSizing(), FitSizing())

    options = options or {}

    if type(value) == "function" then
        value = value()
    end
    self.value = value

    self.list = list

    self.text = Text(list[value])
    self:addChild(self.text)

    self.on_changed = on_changed

    self.color = options.color or COLORS.white
    self.selected_color = options.selected_color or COLORS.yellow
end

function ListMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self:setFocused(true)
    if self.selected_color then
        self.text:setColor(self.selected_color)
    end
end

function ListMenuItemComponent:update()
    super.update(self)

    if self:isFocused() then
        if Input.pressed("left") then
            self.value = self.value - 1
            if self.value < 1 then
                self.value = #self.list
            end
            self.text:setText(self.list[self.value])
            if self.on_changed then
                self:on_changed(self.value)
            end
            Assets.playSound("ui_move")
        end
        if Input.pressed("right") then
            self.value = self.value + 1
            if self.value > #self.list then
                self.value = 1
            end
            self.text:setText(self.list[self.value])
            if self.on_changed then
                self:on_changed(self.value)
            end
            Assets.playSound("ui_move")
        end
        if Input.pressed("confirm") or Input.pressed("cancel") then
            self:setFocused(false)
            Assets.playSound("ui_select")
            Input.clear("confirm")
            if self.color then
                self.text:setColor(self.color)
            end
        end
    end
end

return ListMenuItemComponent
