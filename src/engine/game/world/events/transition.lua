---@class Transition : Event
---@overload fun(...) : Transition
local Transition, super = Class(Event)

function Transition:init(x, y, w, h, properties)
    super.init(self, x, y, w, h)

    properties = properties or {}

    self.target = {
        map = properties.map,
        shop = properties.shop,
        x = properties.x,
        y = properties.y,
        marker = properties.marker,
        facing = properties.facing,
    }
    self.stairs = properties.stairs
    self.lancer = properties.lancer
    self.lancer_exit = properties.lancer_exit
    self.door = properties.door
    self.sound = properties.sound or nil
    self.pitch = properties.pitch or 1
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

        if self.stairs then
            Assets.playSound("escaped")
        end
        if self.lancer then
            Assets.playSound("splat")
        end
        if self.lancer_exit then
            Assets.playSound("reverse_splat")
        end
        if self.door then
            self.world.timer:script(function(wait)
                Assets.playSound("dooropen")
                wait(0.4)
                Assets.playSound("doorclose")
            end)
        end

        if self.sound then
            Assets.playSound(self.sound, 1, self.pitch)
        end

        if self.target.shop then
            self.world:shopTransition(self.target.shop, {x=x, y=y, marker=marker, facing=facing, map=self.target.map})
        elseif self.target.map then
            if marker then
                self.world:mapTransition(self.target.map, marker, facing)
            else
                self.world:mapTransition(self.target.map, x, y, facing)
            end
        end
    end
end

return Transition