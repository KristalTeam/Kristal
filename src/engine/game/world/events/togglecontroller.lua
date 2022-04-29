local ToggleController, super = Class(Event)

function ToggleController:init(properties)
    super:init(self)

    properties = properties or {}

    self.flag = properties["flag"]
    self.value = properties["value"]
    self.invert = properties["inverted"] or false

    self.target_objs = Utils.parsePropertyList("target", properties)
end

function ToggleController:postLoad()
    self.targets = {}
    for _,obj in ipairs(self.target_objs) do
        local target = self.world.map:getEvent(obj.id)
        if target then
            table.insert(self.targets, target)
        end
    end

    if self.active then
        self:updateTargets()
    end
end

function ToggleController:updateTargets()
    local flag = Game:getFlag(self.flag)
    local success = (self.value ~= nil and flag == self.value) or (self.value == nil and flag)
    if self.invert then
        success = not success
    end
    if success then
        for _,target in ipairs(self.targets) do
            target.active = true
            target.visible = true
            target.collidable = true
        end
    else
        for _,target in ipairs(self.targets) do
            target.active = false
            target.visible = false
            target.collidable = false
        end
    end
end

function ToggleController:update()
    self:updateTargets()

    super:update(self)
end

return ToggleController