---@class Legend : Object
---@overload fun(...) : Legend
local Legend, super = Class(Object, "legend")

function Legend:init(cutscene, options)
    super.init(self, 0, 0)

    options = options or {}

    self.can_skip = options["can_skip"] or false
    self.cutscene = cutscene

    self.music = Music(options["music"], options["music_volume"] or 1, options["music_pitch"] or 1)
    if self.music.source then
        self.music.source:setLooping(true)
    end

    self.timer = 0

    self.layers = {
        ["background"] = 0,
        ["panel"     ] = 5,
        ["cover"     ] = 10,
        ["text"      ] = 15,
        ["fader"     ] = 20
    }

    self.background = Sprite("intro/background")
    self.background.layer = self.layers["background"]
    self.background.parallax_x = 0
    self.background.parallax_y = 0
    self:addChild(self.background)

    self.cover = Sprite("intro/cover")
    self.cover.layer = self.layers["cover"]
    self:addChild(self.cover)

    self.fader = Fader(self.layers["fader"])
    self.fader.layer = self.layers["fader"]
    self:addChild(self.fader)

    self.slides = {}
end

function Legend:onFinish(skip)
    self:remove()
    Game.state = "OVERWORLD"
    Game.world.fader:fadeIn(function()
        if not Game.world:hasCutscene() then
            Game.lock_movement = false
        end
    end, { speed = 2, music = true })
end

function Legend:onAddToStage(parent)
    super.onAddToStage(self, parent)

    self.music:play()
    self.cutscene = LegendCutscene(self.cutscene, self.can_skip)
end

function Legend:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end


function Legend:update()
    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update()
            if self.stage == nil then
                return
            end
        else
            self.cutscene = nil
        end
    end

    if self.can_skip and Input.pressed("confirm") then
        self.fader:fadeOut(function() self:onFinish(true) end, { speed = 1, music = true })
    end

    for i, slide in ipairs(self.slides) do
        if slide.fading_out then
            slide.timer = math.max(slide.timer - (0.05 * DTMULT), 0)
            slide.alpha = math.floor((slide.timer - 0.25) / 1 * 4) / 4
            if slide.timer == 0 then
                slide:remove()
                table.remove(self.slides, i)
            end
        else
            slide.timer = math.min(slide.timer + (0.05 * DTMULT), 1)
            slide.alpha = math.floor(slide.timer / 1 * 4) / 4
        end
    end

    super.update(self)
end

function Legend:addSlide(texture)
    local sprite = Sprite(texture)
    sprite.timer = 0
    sprite.layer = self.layers["panel"]
    table.insert(self.slides, sprite)
    self:addChild(sprite)
    return sprite
end

function Legend:removeSlides()
    for i, slide in ipairs(self.slides) do
        slide.fading_out = true
    end
end

return Legend