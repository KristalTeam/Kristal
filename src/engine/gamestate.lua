---@class Gamestate
---
---@field current table The current gamestate.

local Gamestate = {}
local self = Gamestate

Gamestate.current = nil

function Gamestate.getCurrent()
    return Gamestate.current
end

function Gamestate.switch(new)
    local old = Gamestate.current
    if old and old.leave then
        old:leave()
    end

    Gamestate.current = new

    if new.init then
        new:init()
    end

    if new.enter then
        new:enter(old)
    end
end

function Gamestate.update(...)
    if self.current and self.current.update then
        self.current:update(...)
    end
end

function Gamestate.draw(...)
    if self.current and self.current.draw then
        self.current:draw(...)
    end
end

return Gamestate
