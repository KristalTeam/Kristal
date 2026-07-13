---@class TemplateEvent : Event
local event, super = Class(Event, "test_event")

function event:init(data)
    super.init(self, data)

    self.solid = false
    self.unique_id = nil
    self.interact_buffer = 5 / 30

    -- self:setSprite("objects/example")
end

-- Function overrides go here

return event
