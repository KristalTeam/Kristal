--- The handler object for Legend-style cutscenes. \
--- For the object that is received by legend cutscene scripts, see [`LegendCutscene`](lua://LegendCutscene.init).
---@class Legend : GameState
---@overload fun(...) : Legend
local Legend, super = Class(GameState, "legend")

---@param cutscene LegendCutscene
---@param options table
function Legend:init(cutscene, options)
    super.init(self, 0, 0)

    self.music = Music()

    options = options or {}

    self.can_skip = options["can_skip"] or false
    self.cutscene = cutscene
    self.music_options = {
        name = options["music"] --[[@as string?]],
        volume = options["music_volume"] or 1,
        pitch = options["music_pitch"] or 1,
    }
    if self.music.source then
        self.music.source:setLooping(true)
    end

    self.timer = 0

    self.layers = {
        ["background"] = 0,
        ["panel"] = 5,
        ["cover"] = 10,
        ["text"] = 15,
        ["fader"] = 20
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

function Legend:shouldHideOtherStates()
    -- Some projects rely on the world updating for playing legends during world cutscenes.
    return false
end

function Legend:getLegacyGameStateID()
    return "LEGEND"
end

function Legend:enter()
    -- Don't create a `Music` instance since that's done in `init`
    self:onEnter()
end

function Legend:onEnter()
    if self.music_options.name ~= nil then
        self.music:play(self.music_options.name, self.music_options.volume, self.music_options.pitch)
    end
end

function Legend:onFinish(skip)
    Game:popState()
    Game.world.fader:fadeIn(
        function()
            if not Game.world:hasCutscene() then
                Game.lock_movement = false
            end
        end, { speed = 2, music = true }
    )
end

function Legend:onAddToStage(parent)
    super.onAddToStage(self, parent)

    self.music:play()
    self.cutscene = LegendCutscene(self.cutscene, self.can_skip)
end

function Legend:onRemove(parent)
    super.onRemove(self, parent)
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
