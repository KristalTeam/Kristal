---@class GameState: Object
---@field music Music
local GameState, super = Class(Object)

function GameState:enter()
    self.music = Music()
    self:onEnter()
end

---@protected
function GameState:onEnter() end

function GameState:exit()
    self.music:remove()
    self:onExit()
end

---@protected
function GameState:onExit() end

function GameState:shouldHideOtherStates()
    return false
end

-- *Override* Called when a keyboard key or gamepad button is pressed while
-- this state is active.
function GameState:onKeyPressed(key, is_repeat) end

-- *Called internally* Used to set the Game.state field for states made prior
-- to the introduction of the GameState parent class. You shouldn't need to
-- override this.
function GameState:getLegacyGameStateID()
    return "CUSTOM"
end

-- *Override* Checks if this state's music is considered "active". If not,
-- Game:getActiveMusic() will fall back to the next state in the stack.
-- Result is assumed to remain consistent throughout the lifetime of the object.
---@return boolean
function GameState:isMusicActive()
    return false
end

function GameState:getMusic()
    return self.music
end

return GameState

