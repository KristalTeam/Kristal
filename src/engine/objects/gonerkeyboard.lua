---@class GonerKeyboard : Object
---@overload fun(...) : GonerKeyboard
local GonerKeyboard, super = Class(Object)

-- For japanese support in the future maybe
GonerKeyboard.MODES = {
    ["default"] = {
        x      = 136,
        y      = 140,
        step_x = 40,
        step_y = 40,
        name_y = 80,
        keyboard = {
            {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"},
            {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"},
            {"U", "V", "W", "X", "Y", "Z", "BACK", "<<", "END", "<<"}
        }
    },
    ["lowercase"] = {
        x      = 136,
        y      = 140,
        step_x = 40,
        step_y = 40,
        name_y = 80,
        keyboard = {
            {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"},
            {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"},
            {"U", "V", "W", "X", "Y", "Z", "<<", "<<", "<<", "<<"},
            {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j"},
            {"k", "l", "m", "n", "o", "p", "q", "r", "s", "t"},
            {"u", "v", "w", "x", "y", "z", "BACK", "<<", "END", "<<"}
        }
    }
}

function GonerKeyboard:init(limit, mode, callback, key_callback)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.limit = limit or -1
    self.mode = nil

    self.callback = callback
    self.key_callback = key_callback

    self.allow_empty = false

    self.choicer = GonerChoice()
    self.choicer:setSoulOffset(0, -4)
    self.choicer:setWrap(true)
    self.choicer.soul.alpha = 0.5
    self.choicer.soul_speed = 0.5
    self.choicer.teleport = true
    self.choicer.cancel_repeat = true
    self.choicer.on_select = function(choice, x, y)
        self:onSelect(choice, x, y)
        return false
    end
    self.choicer.on_cancel = function(choice, x, y)
        self:undoCharacter()
    end
    self.choicer.on_complete = function(choice, x, y)
        self:onComplete(self.text)
    end
    self:addChild(self.choicer)

    self:setMode(mode or "default")

    self.choicer:resetSoulPosition()

    self.font = Assets.getFont("main")

    self.text = ""
    self.fade_out = false
    self.done = false
end

function GonerKeyboard:setMode(mode)
    if type(mode) == "string" then
        mode = GonerKeyboard.MODES[mode]
    end

    -- Fill out defaults
    self.mode = Utils.copy(GonerKeyboard.MODES["default"])
    Utils.merge(self.mode, mode)

    local choices = self:createKeyboardChoices(self.mode)
    self.choicer:setChoices(choices)

    self.choicer:resetSoulTarget()
end

function GonerKeyboard:createKeyboardChoices(mode)
    local key_choices = {}
    for y, row in ipairs(mode.keyboard) do
        local choice_row = {}
        table.insert(key_choices, choice_row)
        for x, key in ipairs(row) do
            table.insert(choice_row, {key, mode.x + (x - 1) * mode.step_x, mode.y + (y - 1) * mode.step_y})
        end
    end
    return key_choices
end

function GonerKeyboard:update()
    super.update(self)

    self.alpha = self.choicer.alpha
end

function GonerKeyboard:onSelect(key, x, y)
    if self.key_callback then
        local result = self.key_callback(key, x, y, self)

        if result then
            return
        end
    end

    if key == "BACK" then
        self:undoCharacter()
    elseif key == "END" then
        self:finish()
    elseif #key > 1 then
        Kristal.Console:warn("Unknown command: " .. key)
    else
        self:addCharacter(key)
    end
end

function GonerKeyboard:onComplete(text)
    if self.callback then
        self.callback(text, self)
    end
    self.done = true
    self:remove()
end

function GonerKeyboard:undoCharacter()
    if #self.text > 0 then
        self.text = self.text:sub(1, #self.text - 1)
    end
end

function GonerKeyboard:addCharacter(key)
    if self.limit < 0 or #self.text < self.limit then
        self.text = self.text .. key
    end
end

function GonerKeyboard:finish()
    if self.fade_out then return end

    if self.allow_empty or self.text ~= "" then
        self.fade_out = true
        self.choicer:finish()
    end
end

function GonerKeyboard:draw()
    super.draw(self)

    love.graphics.setFont(self.font)

    if self.limit >= 0 and #self.text >= self.limit then
        Draw.setColor(1, 1, 0, self.alpha)
    else
        Draw.setColor(1, 1, 1, self.alpha)
    end

    local w = self.font:getWidth(self.text)

    love.graphics.print(self.text, (SCREEN_WIDTH / 2) - (w / 2), self.mode.name_y)
end

return GonerKeyboard