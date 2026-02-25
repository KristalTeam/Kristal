---@class TransitionProperties
---@field map string? The name of the map to send the player to
---@field shop string? The name of the shop to send the player to
---@field x number? The x coordinate the player should appear at in the new map
---@field y number? The y coordinate the player should appear at in the new map
---@field marker string? The name of the marker to spawn the player at in the new map
---@field facing string? The direction the player and party should face when they spawn in the new map
---@field sound string? An optional sound to play when the player activates this transition
---@field pitch number? The pitch the entry sound should play at
---@field exit_delay number? Additional delay after entering the new map before playing the exit sound, in seconds
---@field exit_sound string? An optional sound to play when entering the new map
---@field exit_pitch number? The pitch the exit sound should play at

--- This object is used to create transitions in the Overworld to shops or other maps. \
--- `Transition` is an [`Event`](lua://Event.init) - Naming an object `transition` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class Transition : Event
---
--- The target of this transition: \
--- *[Property `map`]* The name of the map to send the player to \
--- OR *[Property `shop`]* The name of the shop to send the player to 
---
--- *[Property `x`]* The x co-ordinate the player should appear at in the new map \
--- AND *[Property `y`]* The y-co-ordinate the player should appear at in the new map \
--- OR *[Property `marker`]* The name of the marker to spawn the player at in the new map
--- 
--- *[Property `facing`]* The direction the player and party should face when they spawn in the new map 
---@field target {map: string, shop: string, x: number, y: number, marker: string, facing: string} 
---
---@field sound string? *[Property `sound`]* An optional sound to play when the player activates this transition
---@field pitch number  *[Property `pitch`]* The pitch the entry sound should play at
---
---@field exit_delay number     *[Property `exit_delay`]* Additional delay after entering the new map before playing the exit sound, in seconds (Defaults to `0`)
---@field exit_sound string?    *[Property `exit_sound`]* An optional sound to play when entering the new map
---@field exit_pitch number     *[Property `exit_pitch`]* The pitch the exit sound should play at
---
---@overload fun(...) : Transition
local Transition, super = Class(Event)

---@param properties TransitionProperties
function Transition:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.target = {
        map = properties.map,
        shop = properties.shop,
        x = properties.x,
        y = properties.y,
        marker = properties.marker,
        facing = properties.facing,
    }
    self.sound = properties.sound or nil
    self.pitch = properties.pitch or 1

    self.exit_delay = properties.exit_delay or 0
    self.exit_sound = properties.exit_sound or nil
    self.exit_pitch = properties.exit_pitch or 1
end

function Transition:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.target.map then table.insert(info, "Map: " .. self.target.map) end
    if self.target.shop then table.insert(info, "Shop: " .. self.target.shop) end
    if self.target.x then table.insert(info, "X: " .. self.target.x) end
    if self.target.y then table.insert(info, "Y: " .. self.target.y) end
    if self.target.marker then table.insert(info, "Marker: " .. self.target.marker) end
    if self.target.facing then table.insert(info, "Facing: " .. self.target.facing) end
    return info
end

function Transition:onEnter(chara)
    if chara.is_player then
        local x, y = self.target.x, self.target.y
        local facing = self.target.facing
        local marker = self.target.marker

        if self.sound then
            Assets.playSound(self.sound, 1, self.pitch)
        end

        if self.target.shop then
            self.world:shopTransition(
                self.target.shop,
                {
                    x = x,
                    y = y,
                    marker = marker,
                    facing = facing,
                    map = self.target.map
                }
            )
        elseif self.target.map then
            local callback = function(map)
                if self.exit_sound then
                    Assets.playSound(self.exit_sound, 1, self.exit_pitch)
                end
                Game.world.door_delay = self.exit_delay
            end

            if marker then
                self.world:mapTransition(self.target.map, marker, facing or chara.facing, callback)
            else
                self.world:mapTransition(self.target.map, x, y, facing or chara.facing, callback)
            end
        end
    end
end

return Transition
