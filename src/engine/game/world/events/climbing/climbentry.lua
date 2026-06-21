---@alias ClimbExitRef KristalObjectRef|ClimbExit

--- The settings for a ClimbEntry.
---@class ClimbEntrySettings
---@field solid boolean?
---@field target ClimbExitRef?

--- A ClimbEntry allows the player to begin climbing on climbable areas.
---
--- `ClimbEntry` is an [`Event`](lua://Event.init) - naming an object `climbentry` on an `objects` layer in a map creates this object.
---
---@class ClimbEntry : Event
---
---@field target_identifier ClimbExitRef? The identifier of the ClimbExit that this ClimbEntry leads to.
---@field target ClimbExit? The target ClimbExit that this ClimbEntry leads to.
---
---@overload fun(...) : ClimbEntry
local ClimbEntry, super = Class(Event)

---@param x number?
---@param y number?
---@param shape EventShape?
---@param settings ClimbEntrySettings?
function ClimbEntry:init(x, y, shape, settings)
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)

    settings = settings or {}

    self.solid = settings["solid"]

    if self.solid == nil then
        self.solid = true
    end

    --- Unfortunately, we can't just rely on an object reference -- the exit may not be loaded yet!

    self.target_identifier = settings["target"]

    if isClass(self.target_identifier) and self.target_identifier:includes(ClimbExit) then
        self.target = self.target_identifier
    else
        self.target = nil
    end
end

function ClimbEntry:onLoad()
    if self.target ~= nil then
        return
    end

    -- Unfortunately we have to grab our target now (instead of init).
    local target = Game.world.map:getEvent(self.target_identifier)

    if target ~= nil and isClass(target) and target:includes(ClimbExit) then
        self.target = target --[[@as ClimbExit]]
    else
        target = nil
    end

    if target == nil then
        error(string.format("ClimbEntry at (%d, %d) has invalid or missing target", self.x, self.y))
    end
end

function ClimbEntry:onInteract(player, dir)
    local x, y = self.target:getRelativeJumpTarget()
    local world_x, world_y = self.target:getRelativePos(x, y, Game.world)

    local target_x, target_y = Game.world:getRelativePos(world_x, world_y, player.parent)

    local exit_direction = self.target:getExitDirection()
    local facing_direction = nil

    if exit_direction == "up" then
        facing_direction = "down"
    elseif exit_direction == "down" then
        facing_direction = "up"
    elseif exit_direction == "left" then
        facing_direction = "right"
    elseif exit_direction == "right" then
        facing_direction = "left"
    end

    player:setState("CLIMB_MOUNT", {
        target_x = target_x,
        target_y = target_y,
        facing_direction = facing_direction
    })

    return true
end

return ClimbEntry
