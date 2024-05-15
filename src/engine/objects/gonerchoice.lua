---@class GonerChoice : Object
---@overload fun(...) : GonerChoice
local GonerChoice, super = Class(Object)

function GonerChoice:init(x, y, choices, on_complete, on_select)
    super.init(self, x, y)

    self.choices = choices or {
        {{"YES",0,0},{"NO",80,0}}
    }

    self.on_select = on_select
    self.on_cancel = nil
    self.on_hover = nil
    self.on_complete = on_complete

    self.choice = nil
    self.choice_x = nil
    self.choice_y = nil

    self.done = false

    -- FADEIN, CHOICE, FADEOUT
    self.state = "FADEIN"

    self.alpha = 0

    self.font = Assets.getFont("main")

    self.soul = Sprite("player/heart_blur")
    self.soul:setScale(2, 2)
    self.soul:setColor(Kristal.getSoulColor())
	if MainMenu.mod_list:getSelectedMod().soulColor and Kristal.getState() ~= Game then
		self.soul:setColor(unpack(MainMenu.mod_list:getSelectedMod().soulColor))
	end
    self.soul.alpha = 0.6
    self.soul.inherit_color = true
    self:addChild(self.soul)

    self.wrap_x = false
    self.wrap_y = false

    self.teleport = false
    self.cancel_repeat = false

    self.selected_x = 1
    self.selected_y = 1

    self.soul_offset_x = 0
    self.soul_offset_y = 0

    self.soul_target_x = 0
    self.soul_target_y = 0

    self.soul_align = "center"
    self.soul_speed = 0.3

    self:clampSelection()
    self:resetSize()
    self:resetSoulPosition()
end

-- Overridable Callbacks

function GonerChoice:onSelect(choice, x, y) end
function GonerChoice:onCancel(choice, x, y) end
function GonerChoice:onHover(choice, x, y) end

function GonerChoice:onComplete(choice, x, y) end

-- Intialization Setters

function GonerChoice:setChoices(choices, selected_x, selected_y)
    self.choices = choices or {
        {{"NO",0,0},{"YES",80,0}}
    }

    self.selected_x = selected_x or 1
    self.selected_y = selected_y or 1

    self:clampSelection()
    self:resetSize()
end

function GonerChoice:setChoice(x, y, choice)
    if y < 1 or y > #self.choices or x < 1 or x > #self.choices[y] + 1 then
        error("Attempt to set choice out of bounds")
    end

    self.choices[y][x] = choice

    if self.selected_x == x and self.selected_y == y then
        self:resetSoulTarget()
    end

    self:resetSize()
end

function GonerChoice:setSoulOffset(x, y)
    self.soul_offset_x = x
    self.soul_offset_y = y
end

function GonerChoice:setSoulTarget(x, y)
    self.soul_target_x = x
    self.soul_target_y = y
end

function GonerChoice:setSoulPosition(x, y, set_target)
    self.soul:setPosition(x, y)
    if set_target ~= false then
        self.soul_target_x = x
        self.soul_target_y = y
    end
end

function GonerChoice:setSoulOrigin(ox, oy)
    self.soul:setOrigin(ox, oy)
    self.soul_origin_x = ox
    self.soul_origin_y = oy or ox
end

function GonerChoice:setWrap(x, y)
    self.wrap_x = x ~= false
    self.wrap_y = y or (y == nil and x)
end

function GonerChoice:setSelectedOption(x, y, move_soul)
    self.selected_x = x
    self.selected_y = y
    self:clampSelection()
    if move_soul ~= false then
        self:resetSoulPosition()
    end
end

function GonerChoice:resetSoulPosition()
    self:setSoulPosition(self:getSoulTarget(self:getChoice(self.selected_x, self.selected_y)))
end

function GonerChoice:resetSoulTarget()
    self:setSoulTarget(self:getSoulTarget(self:getChoice(self.selected_x, self.selected_y)))
end

-- Overridable Getters

function GonerChoice:getSoulTarget(choice, x, y)
    local target_x = (choice[2] or 0) + self.soul_offset_x + (choice[4] or 0)
    local target_y = (choice[3] or 0) + self.soul_offset_y + (choice[5] or 0)

    local w = self.font:getWidth(self:getChoiceText(choice, x, y))
    if self.soul_align == "left" then
        target_x = target_x - (self.soul.width * 2)
    elseif self.soul_align == "center" then
        target_x = target_x + (w / 2) - (self.soul.width)
    elseif self.soul_align == "right" then
        target_x = target_x + w
    end

    return target_x, target_y
end

function GonerChoice:getChoiceText(choice, x, y)
    local escaped = {
        ["\\<<"] = "<<",
        ["\\>>"] = ">>",
        ["\\^^"] = "^^",
        ["\\vv"] = "vv"
    }
    return escaped[choice[1]] or choice[1]
end

function GonerChoice:isHidden(choice, x, y)
    return choice[1] == "<<" or choice[1] == ">>" or choice[1] == "^^" or choice[1] == "vv"
end

-- Internal Functions

function GonerChoice:update()
    if self.state == "FADEIN" then
        self.alpha = Utils.approach(self.alpha, 1, 0.1 * DTMULT)

        if self.alpha == 1 then
            self.state = "CHOICE"
        end
    elseif self.state == "FADEOUT" then
        self.alpha = Utils.approach(self.alpha, 0, 0.1 * DTMULT)

        if self.alpha <= 0 then
            local choice = self:getChoice(self.selected_x, self.selected_y)

            local result = self:onComplete(choice, self.selected_x, self.selected_y)

            if result ~= false and self.on_complete then
                self.on_complete(choice and choice[1], self.selected_x, self.selected_y)
            end

            self.done = true

            self:remove()
        end
    elseif self.state == "CHOICE" then
        if Input.pressed("left", true) then
            self:moveSelection(self.selected_x - 1, self.selected_y, -1, 0)
        end
        if Input.pressed("right", true) then
            self:moveSelection(self.selected_x + 1, self.selected_y, 1, 0)
        end
        if Input.pressed("up", true) then
            self:moveSelection(self.selected_x, self.selected_y - 1, 0, -1)
        end
        if Input.pressed("down", true) then
            self:moveSelection(self.selected_x, self.selected_y + 1, 0, 1)
        end

        if Input.pressed("confirm") then
            self:select(self.selected_x, self.selected_y)
        elseif Input.pressed("cancel", self.cancel_repeat) then
            local choice = self:getChoice(self.selected_x, self.selected_y)

            self:onCancel(choice, self.selected_x, self.selected_y)

            if self.on_cancel then
                self.on_cancel(choice and choice[1], self.selected_x, self.selected_y)
            end
        end
    end

    if math.abs(self.soul.x - self.soul_target_x) <= 2 then
        self.soul.x = self.soul_target_x
    end
    if math.abs(self.soul.y - self.soul_target_y) <= 2 then
        self.soul.y = self.soul_target_y
    end
    local dx = (self.soul_target_x - self.soul.x) * self.soul_speed
    local dy = (self.soul_target_y - self.soul.y) * self.soul_speed
    if self.teleport and math.abs(dx) > 60 then
        self.soul.x = self.soul_target_x
    else
        self.soul.x = self.soul.x + (dx * DTMULT)
    end
    if self.teleport and math.abs(dy) > 60 then
        self.soul.y = self.soul_target_y
    else
        self.soul.y = self.soul.y + (dy * DTMULT)
    end

    super.update(self)
end

function GonerChoice:finish(callback)
    if self.state == "FADEOUT" then return end

    self.state = "FADEOUT"

    local choice = self:getChoice(self.selected_x, self.selected_y)
    self.choice = choice[1]
    self.choice_x = self.selected_x
    self.choice_y = self.selected_y

    if callback then
        self.on_complete = callback
    end
end

function GonerChoice:clampSelection()
    self.selected_x = Utils.clamp(self.selected_x, 1, #self.choices[self.selected_y])
    self.selected_y = Utils.clamp(self.selected_y, 1, #self.choices)
end

function GonerChoice:resetSize()
    local max_x = 0
    local max_y = 0

    for y, row in ipairs(self.choices) do
        for x, choice in ipairs(row) do
            local w, h = self.font:getWidth(self:getChoiceText(choice, x, y)), self.font:getHeight()
            max_x = math.max(max_x, (choice[2] or 0) + w)
            max_y = math.max(max_y, (choice[3] or 0) + h)
        end
    end

    self.width = max_x
    self.height = max_y
end

function GonerChoice:getChoice(x, y)
    return self.choices[y][x], x, y
end

function GonerChoice:select(x, y)
    local choice = self:getChoice(x, y)

    if not self:isHidden(choice, x, y) then
        local result = self:onSelect(choice, x, y)

        if result ~= false and self.on_select then
            result = self.on_select(choice and choice[1], x, y)
        end

        if result ~= false then
            self:finish()
        end
    end
end

function GonerChoice:moveSelection(x, y, dx, dy)
    local choice
    repeat
        if self.wrap_y then
            y = Utils.clampWrap(y, 1, #self.choices)
        else
            y = Utils.clamp(y, 1, #self.choices)
        end
        if self.wrap_x then
            x = Utils.clampWrap(x, 1, #self.choices[y])
        else
            x = Utils.clamp(x, 1, #self.choices[y])
        end

        choice = self.choices[y][x]

        local new_dx, new_dy = 0, 0

        if choice[1] == "<<" then
            new_dx = -1
        elseif choice[1] == ">>" then
            new_dx = 1
        elseif choice[1] == "^^" then
            new_dy = -1
        elseif choice[1] == "vv" then
            new_dy = 1
        end

        if dx and new_dx == -dx then
            new_dx = dx
        end
        if dy and new_dy == -dy then
            new_dy = dy
        end

        x = x + new_dx
        y = y + new_dy
    until choice[1] ~= "<<" and choice[1] ~= ">>" and choice[1] ~= "^^" and choice[1] ~= "vv"

    local result = self:onHover(choice, x, y)

    if result ~= false and self.on_hover then
        result = self.on_hover(choice and choice[1], x, y)
    end

    if result ~= false then
        self.selected_x = x
        self.selected_y = y

        self:resetSoulTarget()
    end
end

function GonerChoice:draw()
    super.draw(self)

    love.graphics.setFont(self.font)
    for y, row in ipairs(self.choices) do
        for x, choice in ipairs(row) do
            local text = self:getChoiceText(choice, x, y)

            local tx = (choice[2] or 0)
            local ty = (choice[3] or 0)

            if not self:isHidden(choice, x, y) then
                if self.selected_x == x and self.selected_y == y then
                    Draw.setColor(1, 1, 0, self.alpha)
                    love.graphics.print(text, tx, ty)
                else
                    Draw.setColor(1, 1, 1, self.alpha)
                    love.graphics.print(text, tx, ty)
                end
            end
        end
    end
end

return GonerChoice
