---@class TemplateWave : Wave
local wave, super = Class(Wave, "test_wave")

function wave:init()
    super.init(self)

    self.time = 5

    -- Optional arena overrides.
    self.arena_x = nil
    self.arena_y = nil
    self.arena_width = nil
    self.arena_height = nil
    self.arena_shape = nil
    self.arena_rotation = 0
    self.has_arena = true

    self.spawn_soul = true
    self.soul_start_x = nil
    self.soul_start_y = nil
    self.soul_offset_x = nil
    self.soul_offset_y = nil
end

-- Function overrides go here

return wave
