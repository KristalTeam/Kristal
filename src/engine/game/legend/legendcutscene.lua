--- A special cutscene class for Legend-style cutscenes. \
--- Write an annotation here about how these cutscenes start!
---
---@class LegendCutscene : Cutscene
---
--- A table of preset positions for use with `LegendCutscene:text()`. \
--- Available positions: `"far_left"`, `"far_right"`, `"left"`, `"top_left"`, \
--- `"middle_bottom"`, `"left_bottom"`, `"far_left_bottom"`, `"text_human"`, \
--- `"text_monster"`, `"text_prince"`.
---@field text_positions table
---
--- The speed that newly created text will type at in the cutscene, in characters per frame.
---@field speed number
---
---@overload fun(...) : LegendCutscene
local LegendCutscene, super = Class(Cutscene, "LegendCutscene")

---@enum (key) LegendCutscene.TEXT_POSITIONS
LegendCutscene.TEXT_POSITIONS = {
    ["far_left"] = { 80, 320 },
    ["far_right"] = { 440, 320 },
    ["left"] = { 160, 320 },
    ["top_left"] = { 80, 160 },
    ["middle_bottom"] = { 160, 370 },
    ["left_bottom"] = { 120, 370 },
    ["far_left_bottom"] = { 80, 370 },
    ["text_human"] = { 40, 370 },
    ["text_monster"] = { 220, 370 },
    ["text_prince"] = { 400, 370 }
}

function LegendCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getLegendCutscene, group, id, ...)

    self.text_objects = {}

    self.speed = 1

    super.init(self, scene, ...)
end

function LegendCutscene:update()
    super.update(self)
end

function LegendCutscene:onEnd()
    super.onEnd(self)

    Game.legend.fader:fadeOut(function() Game.legend:onFinish() end, { speed = 2, music = true })
end

--- Removes all currently active text objects from the cutscene.
function LegendCutscene:removeText()
    for i, v in ipairs(self.text_objects) do
        v:remove()
    end
end

--- Sets the typing speed of the legend text. \
--- Default typing speed is `1`.
---@param speed number  The speed, in characters typed per frame.
function LegendCutscene:setSpeed(speed)
    self.speed = speed
end

--- Writes some text at the given coordinates on the screen.
---@param text  string  The text to display.
---@param pos   LegendCutscene.TEXT_POSITIONS|table<number, number> A table of the x and y coordinates to start writing the text at. See `LegendCutscene.TEXT_POSITIONS` for a set of default text positions.
---@return DialogueText dialogue
function LegendCutscene:text(text, pos)
    local x, y = 0, 0

    if type(pos) == "string" then
        pos = LegendCutscene.TEXT_POSITIONS[pos]
        if pos == nil then
            error("Invalid LegendCutscene:text() position key: " .. pos)
        end

        x, y = unpack(pos)
    elseif type(pos) == "table" then
        x = pos[1]
        y = pos[2]
    else
        error("Invalid position argument to LegendCutscene:text(); expected string or table, got " .. type(pos))
    end

    local dialogue = Game.legend:addChild(DialogueText(text, x, y, nil, nil, { style = "none" }))
    dialogue.state.speed = self.speed
    dialogue.state.typing_sound = nil
    dialogue.layer = Game.legend.layers["text"]
    dialogue.parallax_x = 0
    dialogue.parallax_y = 0
    dialogue.skippable = false
    table.insert(self.text_objects, dialogue)
    return dialogue
end

--- Suspends the cutscene until the music reaches a certain runtime.
---@param time number   The song runtime to wait until before resuming the cutscene, in seconds.
---@return any
function LegendCutscene:musicWait(time)
    return self:wait(function() return Game.legend.music:tell() >= time end)
end

--- Adds a new picture slide to the legend.
---@param texture string  The path to the texture for the new slide.
---@return Sprite slide The sprite created for the new panel.
function LegendCutscene:slide(texture)
    return Game.legend:addSlide(texture)
end

--- Starts fading out the currently visible slides.
---@return nil
function LegendCutscene:removeSlides()
    return Game.legend:removeSlides()
end

--- Hides the legend's "cover" sprite, which obscures the current slide.
function LegendCutscene:hideCover()
    Game.legend.cover.visible = false
end

--- Shows the legend's "cover" sprite, which obscures the current slide.
function LegendCutscene:showCover()
    Game.legend.cover.visible = true
end

--- Sets the texture of the legend's "cover" sprite, which obscures the current slide. \
---@param texture string The path to the texture to set on the cover sprite.
function LegendCutscene:setCover(texture)
    Game.legend.cover:setTexture(texture)
end

--- Resets the texture of the legend's "cover" sprite to its default texture.
function LegendCutscene:resetCover()
    Game.legend.cover:setTexture("intro/cover")
end

return LegendCutscene
