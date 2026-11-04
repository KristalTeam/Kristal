---@class TemplateActor : Actor
local actor, super = Class(Actor, "test_actor")

function actor:init()
    super.init(self)

    -- Display name (optional)
    self.name = "Test Actor"

    -- Width and height for this actor, used to determine its center
    self.width = 16
    self.height = 16

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {0, 0, 16, 16}

    -- Position of the Soul on this actor when used as the player
    self.soul_offset = {10, 24}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 0}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = nil

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/kris/dark"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "walk"

    -- More explicit alternatives to default (optional)
    self.default_sprite = nil
    self.default_anim = nil

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Font and text layout used when this actor speaks (optional)
    self.font = nil
    self.speech_bubble_font_size = nil
    self.indent_string = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil
    -- Miniface and its offset for dialogue (optional)
    self.miniface = nil
    self.miniface_offset = nil

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of talk sprites and their talk speeds (default 0.25)
    self.talk_sprites = {}

    -- Per-sprite flip overrides, used when self.flip is nil
    self.flip_sprites = {}

    -- Sprite substitutions used in mirrors
    self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",
    }

    -- Table of sprite animations
    self.animations = {}

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {}
end

-- Function overrides go here

return actor
