---@class TemplateEncounter : Encounter
local encounter, super = Class(Encounter, "test_encounter")

function encounter:init()
    super.init(self)

    self.text = "* A battle begins!"
    self.music = "battle"
    self.background = true
    self.hide_world = false
    self.default_xactions = Game:getConfig("partyActions")
    self.no_end_message = false
    self.reduced_tension = false

    -- Add enemies here. Positions are optional.
    -- self:addEnemy("enemy_id", 320, 240)
end

-- Function overrides go here

return encounter
