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

    self.on_changed = on_changed

    self.color = options.color or COLORS.white
    self.selected_color = options.selected_color or COLORS.yellow

    self.prefix = options.prefix or ""
    self.suffix = options.suffix or ""

    self.wrap = options.wrap ~= false

    self.hold = options.hold or false

    self.text = Text(self.prefix .. list[value] .. self.suffix)
    self:addChild(self.text)

    self.step = options.step or 1
    self.delay = 0

    self.sound_timer = 0
    self.sound_delay = options.sound_delay or 1
    self.sound = options.sound or "ui_move"
    self.sound_at_limit = options.sound_at_limit or false

    self.hold = options.hold or false
end

function ListMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    self:setFocused(true)
    if self.selected_color then
        self.text:setColor(self.selected_color)
    end
end

function ListMenuItemComponent:updateSelected()
    self.text:setText(self.prefix .. self.list[self.value] .. self.suffix)
    if self.on_changed then
        self.on_changed(self.value)
    end
    self:reflow()
end

function ListMenuItemComponent:previous()
    self.value = self.value - 1
    self:keepInRange()
end

function ListMenuItemComponent:next()
    self.value = self.value + 1
    self:keepInRange()
end

function ListMenuItemComponent:keepInRange()
    if self.value < 1 then
        self.value = self.wrap and #self.list or 1
    elseif self.value > #self.list then
        self.value = self.wrap and 1 or #self.list
    end
end

function ListMenuItemComponent:update()
    super.update(self)

    if self.hold then
        self.delay = self.delay - (self.step * DTMULT)
    end

    if self:isFocused() then

        local holding = false
        local selected = self.value
        if self.hold then
            while (self.delay <= 0) do
                if (Input.down("left")) then
                    holding = true
                    self:previous()
                    self.delay = self.delay + 1
                elseif (Input.down("right")) then
                    holding = true
                    self:next()
                    self.delay = self.delay + 1
                else
                    self.delay = 0
                    break
                end
            end
        else
            if Input.pressed("left", self.hold) then self:previous() end
            if Input.pressed("right", self.hold) then self:next() end
        end

        self.sound_timer = self.sound_timer - DTMULT
        if self.value ~= selected or (self.sound_at_limit and holding) then
            self:updateSelected()
            if (self.sound_timer <= 0) then
                self.sound_timer = self.sound_delay
                Assets.playSound(self.sound)
            end
        else
            self.sound_timer = 0
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
