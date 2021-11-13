return {
    -- Actor ID (optional, defaults to path)
    id = "test_actor",
    -- Display name (optional)
    name = "Test Actor",

    -- Width and height for this actor, used to determine its center
    width = 16,
    height = 16,

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    hitbox = nil,

    -- Color for this actor used in outline areas (optional, defaults to red)
    color = nil,

    -- Path to this actor's sprites (defaults to "")
    path = "party/kris",
    -- This actor's default sprite, relative to the path (defaults to "")
    default = "world/dark",

    -- Table of sprite animations
    animations = {},

    -- Table of sprite offsets (indexed by sprite name)
    offsets = {},
}