--- A controller that toggles the existence of events in maps in the Overworld. \
--- Unlike load control properties such as `flagcheck` and `cond`, toggle immediately updates the loaded state of objects based on its flag, rather than requiring a room reload. \
--- `ToggleController` is a `controller` - naming an object `toggle` on a `controllers` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class ToggleController : Event
---
---@field flag              string  *[Property `flag`]* The name of the flag to check for whether targets should be active - if `!` is at the start of the flag, the check will be [`inverted`](lua://ToggleController.inverted)
---@field inverted          boolean *[Property `inverted`]* Whether the flagcheck is inverted such that if `flag` is `flag_value`, the controller targets are inactive, and active otherwise
---@field flag_value        boolean *[Property `value`]* The value that `flag` should be for the controller targets to be active
---
---@field target_objs (Character|Event)[]   *[Property list `target`]* A list of objects that this controller is attached to
---
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