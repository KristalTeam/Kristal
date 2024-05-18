local LegendCutscene, super = Class(Cutscene, "LegendCutscene")

function LegendCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getLegendCutscene, group, id, ...)

    self.text_objects = {}

    self.text_positions = {
        ["far_left"       ] = {80 , 320},
        ["far_right"      ] = {440, 320},
        ["left"           ] = {160, 320},
        ["top_left"       ] = {80 , 160},
        ["middle_bottom"  ] = {160, 370},
        ["left_bottom"    ] = {120, 370},
        ["far_left_bottom"] = {80 , 370},
        ["text_human"     ] = {40 , 370},
        ["text_monster"   ] = {220, 370},
        ["text_prince"    ] = {400, 370}
    }

    self.speed = 1

    super:init(self, scene, ...)
end

function LegendCutscene:update()
    super.update(self)
end

function LegendCutscene:onEnd()
    super.onEnd(self)

    Game.legend.fader:fadeOut(function() Game.legend:onFinish() end, { speed = 2, music = true })
end

function LegendCutscene:removeText()
    for i, v in ipairs(self.text_objects) do
        v:remove()
    end
end

function LegendCutscene:setSpeed(speed)
    self.speed = speed
end

function LegendCutscene:text(text, pos)
    local x, y = unpack(self.text_positions[pos])
    local dialogue = Game.legend:addChild(DialogueText(text, x, y, nil, nil, {style = "none"}))
    dialogue.state.speed = self.speed
    dialogue.state.typing_sound = nil
    dialogue.layer = Game.legend.layers["text"]
    dialogue.parallax_x = 0
    dialogue.parallax_y = 0
    dialogue.skippable = false
    table.insert(self.text_objects, dialogue)
    return dialogue
end

function LegendCutscene:musicWait(time)
    return self:wait(function() return Game.legend.music:tell() >= time end)
end

function LegendCutscene:slide(texture)
    return Game.legend:addSlide(texture)
end

function LegendCutscene:removeSlides()
    return Game.legend:removeSlides()
end

return LegendCutscene