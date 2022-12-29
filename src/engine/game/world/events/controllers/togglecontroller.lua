---@class ToggleController : Event
---@overload fun(...) : ToggleController
local ToggleController, super = Class(Event, "toggle")

function ToggleController:init(properties)
    super.init(self)

    properties = properties or {}

    self.flag, self.inverted, self.value = Utils.parseFlagProperties("flag", "inverted", "value", nil, properties)

    self.target_objs = Utils.parsePropertyList("target", properties)
end

function ToggleController:onLoad()
    self.targets = {}
    self.target_colliders = {}
    for _,obj in ipairs(self.target_objs) do
        local target = self.world.map:getEvent(obj.id)
        if target then
            table.insert(self.targets, target)
        else
            local collider_target = self.world.map:getHitbox(obj.id)
            if collider_target then
                table.insert(self.target_colliders, collider_target)
            end
        end
    end

    if self.active then
        self:updateTargets()
    end
end

function ToggleController:updateTargets()
    local flag = Game:getFlag(self.flag, false) or (self.world and self.world.map:getFlag(self.flag, false))
    local success = (self.value ~= nil and flag == self.value) or (self.value == nil and flag)
    if self.inverted then
        success = not success
    end
    if success then
        for _,target in ipairs(self.targets) do
            target.active = true
            target.visible = true
            target.collidable = true
        end
        for _,target in ipairs(self.target_colliders) do
            target.collidable = true
        end
    else
        for _,target in ipairs(self.targets) do
            target.active = false
            target.visible = false
            target.collidable = false
        end
        for _,target in ipairs(self.target_colliders) do
            target.collidable = false
        end
    end
end

function ToggleController:update()
    self:updateTargets()

    super.update(self)
end

return ToggleController