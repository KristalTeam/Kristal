---@class EditorModeTransition : Class
---@overload fun(direction: "enter"|"exit", on_handoff?: function, on_complete?: function): EditorModeTransition
local EditorModeTransition = Class()

local ENTER_OPEN_DURATION = 4 / 30
local ENTER_HOLD_DURATION = 12 / 30
local ENTER_CLOSE_DURATION = 4 / 30
local EXIT_OPEN_DURATION = 4 / 30
local EXIT_HOLD_DURATION = 9 / 30
local EXIT_CLOSE_DURATION = 4 / 30
local BAR_HEIGHT = 32
local PIXEL_SIZE = 4
local STRIPE_WIDTH = 16
local SCROLL_SPEED = 160

function EditorModeTransition:init(direction, on_handoff, on_complete)
    assert(direction == "enter" or direction == "exit", "Unknown editor transition direction")
    self.direction = direction
    if direction == "enter" then
        self.open_duration = ENTER_OPEN_DURATION
        self.hold_duration = ENTER_HOLD_DURATION
        self.close_duration = ENTER_CLOSE_DURATION
    else
        self.open_duration = EXIT_OPEN_DURATION
        self.hold_duration = EXIT_HOLD_DURATION
        self.close_duration = EXIT_CLOSE_DURATION
    end
    self.duration = self.open_duration + self.hold_duration + self.close_duration
    self.timer = 0
    self.on_handoff = on_handoff
    self.on_complete = on_complete
    self.handoff_reached = false
    self.complete = false

    if direction == "enter" then
        self.square_sound = Assets.newSound("dtrans_square")
        self.square_sound:setVolume(0.5)
        self.square_times = { 0, 3 / 30, 6 / 30 }
        self.next_square = 1
        self.flip_time = 8 / 30
        self.flip_played = false
        self:playSquare()
    else
        Assets.playSound("dtrans_lw")
    end
end

function EditorModeTransition:playSquare()
    self.square_sound:stop()
    self.square_sound:play()
    self.next_square = self.next_square + 1
end

function EditorModeTransition:update(dt)
    if self.complete then return end
    self.timer = math.min(self.duration, self.timer + dt)

    if self.direction == "enter" then
        while self.next_square <= #self.square_times
            and self.timer >= self.square_times[self.next_square] do
            self:playSquare()
        end
        if not self.flip_played and self.timer >= self.flip_time then
            self.flip_played = true
            Assets.playSound("dtrans_flip")
        end
    end

    if not self.handoff_reached and self.timer >= self.open_duration then
        self.handoff_reached = true
        if self.on_handoff then self.on_handoff(self) end
    end

    if self.timer >= self.duration then
        self.complete = true
        if self.on_complete then self.on_complete(self) end
    end
end

function EditorModeTransition:isComplete()
    return self.complete
end

function EditorModeTransition:getOpenAmount()
    if self.timer < self.open_duration then
        return self.timer / self.open_duration
    elseif self.timer < self.open_duration + self.hold_duration then
        return 1
    end
    return 1 - ((self.timer - self.open_duration - self.hold_duration) / self.close_duration)
end

function EditorModeTransition:drawBar(y, height, scroll_direction)
    if height <= 0 then return end
    Draw.setColor(0.03, 0.03, 0.035, 1)
    love.graphics.rectangle("fill", 0, y, SCREEN_WIDTH, height)

    local scroll = math.floor(self.timer * SCROLL_SPEED / PIXEL_SIZE) * PIXEL_SIZE * scroll_direction
    for row = 0, height - 1, PIXEL_SIZE do
        local row_height = math.min(PIXEL_SIZE, height - row)
        for x = -STRIPE_WIDTH, SCREEN_WIDTH + STRIPE_WIDTH, PIXEL_SIZE do
            local stripe = math.floor((x + (row * scroll_direction) + scroll) / STRIPE_WIDTH)
            if stripe % 2 == 0 then
                Draw.setColor(0.88, 0.88, 0.90, 1)
            else
                Draw.setColor(0.12, 0.12, 0.14, 1)
            end
            love.graphics.rectangle("fill", x, y + row, PIXEL_SIZE, row_height)
        end
    end
end

function EditorModeTransition:draw()
    local open = MathUtils.clamp(self:getOpenAmount(), 0, 1)
    local height = MathUtils.round(BAR_HEIGHT * open / PIXEL_SIZE) * PIXEL_SIZE
    height = MathUtils.clamp(height, 0, BAR_HEIGHT)
    local direction = self.direction == "enter" and 1 or -1

    self:drawBar(0, height, direction)
    self:drawBar(SCREEN_HEIGHT - height, height, -direction)
    Draw.setColor(1, 1, 1, 1)
end

return EditorModeTransition
