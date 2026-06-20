---@alias ClimbTargetPosition [number, number]

---@alias ClimbExitTarget string|integer|ClimbTargetPosition|Marker|TiledObjectRef

--- The settings for a ClimbExit.
---@class ClimbExitSettings
---@field target ClimbExitTarget?
---@field direction "up"|"down"|"left"|"right"?
---@field can_exit boolean? If false, the player will not be able to exit through this ClimbExit. Defaults to true.

--- A ClimbExit allows the player to leave climbable areas and stop climbing.
---
--- `ClimbExit` is an [`Event`](lua://Event.init) - naming an object `climbexit` on an `objects` layer in a map creates this object.
---
---@class ClimbExit : Event
---
---@field target_identifier ClimbEntryTarget The identifier of the target event that this ClimbEntry leads to.
---@field target_x number? The x position that the player will jump to.
---@field target_y number? The y position that the player will jump to.
---
---@overload fun(...) : ClimbExit
local ClimbExit, super = Class(Event)

---@param x number?
---@param y number?
---@param shape EventShape?
---@param settings ClimbExitSettings?
function ClimbExit:init(x, y, shape, settings)
    settings = settings or {}
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)

    self.target_identifier = settings.target

    self.target_x = nil
    self.target_y = nil

    self.can_exit = settings.can_exit ~= false

    self.exit = settings.direction
    self.auto_exit = nil

    if self.can_exit and self.target_identifier == nil then
        error(string.format("ClimbExit at (%d, %d) requires a target, found none", self.x, self.y))
    end
end

function ClimbExit:canExit()
    return self.can_exit
end

function ClimbExit:calculateAutoExit()
    local x_diff = self.target_x - self.x
    local y_diff = self.target_y - self.y

    local climb_x = MathUtils.sign(x_diff)
    local climb_y = MathUtils.sign(y_diff)

    if climb_x ~= 0 and climb_y ~= 0 then
        -- Figure out which one went further
        if math.abs(x_diff) > math.abs(y_diff) then
            climb_y = 0
        else
            climb_x = 0
        end
    end

    if climb_x == 0 and climb_y == 0 then
        climb_y = -1
    end

    -- Now we use the directions (and invert them)
    if climb_x == 1 then
        self.auto_exit = "right"
    elseif climb_x == -1 then
        self.auto_exit = "left"
    elseif climb_y == 1 then
        self.auto_exit = "down"
    elseif climb_y == -1 then
        self.auto_exit = "up"
    end
end

function ClimbExit:getRelativeJumpTarget()
    return self.width / 2, self.height / 2
end

---@return "up"|"down"|"left"|"right"|nil
function ClimbExit:getExitDirection()
    if not self.can_exit then
        return nil
    end

    return self.exit or self.auto_exit
end

function ClimbExit:getExitPosition()
    return self.target_x, self.target_y
end

function ClimbExit:onLoad()
    if self.can_exit == false then
        return
    end

    local target = self.target_identifier

    if type(target) == "table" then
        ---@cast target ClimbTargetPosition|Marker|TiledObjectRef
        if target.center_x ~= nil and target.center_y ~= nil then
            -- This is marker data.
            self.target_x = target.center_x
            self.target_y = target.center_y
            self:calculateAutoExit()
            return
        elseif target.id ~= nil then
            -- This is a Tiled object reference.
            ---@cast target TiledObjectRef
            if not Game.world.map:hasMarker(target) then
                error(string.format("ClimbExit at (%d, %d) has invalid target", self.x, self.y))
            end

            self.target_x, self.target_y = Game.world.map:getMarker(target)
            self:calculateAutoExit()
            return
        elseif target[1] ~= nil and target[2] ~= nil then
            -- This is a position table.
            self.target_x = target[1]
            self.target_y = target[2]
            self:calculateAutoExit()
            return
        else
            error(string.format("ClimbExit at (%d, %d) has invalid target", self.x, self.y))
        end
    end

    -- Not a table, could be a string or a number (a marker reference)

    if not Game.world.map:hasMarker(target) then
        error(string.format("ClimbExit at (%d, %d) has invalid target", self.x, self.y))
    end

    self.target_x, self.target_y = Game.world.map:getMarker(target)

    self:calculateAutoExit()
end

function ClimbExit:getDebugInfo()
    local info = super.getDebugInfo(self)
    return info
end

return ClimbExit
