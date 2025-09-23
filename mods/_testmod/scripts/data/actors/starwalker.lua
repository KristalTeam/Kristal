local actor, super = Class(Actor, "starwalker")

function actor:init()
    super.init(self)

    -- Display name (optional)
    self.name = "Starwalker"

    -- Width and height for this actor, used to determine its center
    self.width = 37
    self.height = 36

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {0, 22, 37, 14}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 1, 0}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = nil

    -- Path to this actor's sprites (defaults to "")
    self.path = "npcs/starwalker"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "starwalker"

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of talk sprites and their talk speeds (default 0.25)
    self.talk_sprites = {}

    -- Table of sprite animations
    self.animations = {
        ["wings"] = {"starwalker_wings", 0.25, true},
        ["hurt"] = {"starwalker_shoot_1", 0.5, true},
        ["shoot"] = {"starwalker_wings", 0.25, true, next="wings", frames={5,4,3,2}},
        ["reaching"] = {"starwalker_reaching", 0.25, true},
        ["acting"] = {"starwalker_acting", 2/30, false},
        ["pointing"] = {"starwalker_pointing", 0.25, false},
        ["pointing_up"] = {"starwalker_pointing_up", 1/30, false},
        ["pointing_down"] = {"starwalker_pointing_up", 1/30, false, next="wings", frames={5,4,3,2,1}}
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
        ["starwalker"] = {0, 0},
        ["starwalker_wings"] = {-6, -4},
        ["starwalker_shoot_1"] = {0, 0},
        ["starwalker_shoot_2"] = {-5, 0},
        ["starwalker_reaching"] = {-8, -1},
        ["starwalker_acting"] = {-24, -1},
        ["starwalker_pointing"] = {-8, -1},
        ["starwalker_pointing_up"] = {-6, -11}
    }
end

--[[
function actor:onTextSound(node)
    local pitch = Utils.clampMap(string.byte(node.character), 32, 256, 1, 1.08)
    if Game.battle then
        pitch = Utils.clampMap(string.byte(node.character), 32, 256, 0.5, 2.08)
    end
    Assets.playSound("voice/default", 1, pitch)
    return true
end
]]

return actor
