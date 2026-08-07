--- The settings for ReviveSongEffect.
---@class ReviveSongEffectSettings
---@field on_finish_func fun(obj: ReviveSongEffect)? # A callback function that is called when the ReviveSongEffect finishes. Optional

--- ReviveSongEffect is the object which handles the ReviveSong spell's animation.
---@class ReviveSongEffect : Object
---@overload fun(...) : ReviveSongEffect
local ReviveSongEffect, super = Class(Object)

---@param x number
---@param y number
---@param target_battler PartyBattler
---@param settings ReviveSongEffectSettings? # Optional settings for the effect
function ReviveSongEffect:init(x, y, target_battler, settings)
    super.init(self, x, y, 128, 32)

    settings = settings or {}

    self:setOrigin(0.5, 0.5)

    self.timer = 0
    self.target_battler = target_battler
    self.light_canvas = love.graphics.newCanvas(128, 400)
    self.silhouette_canvas = love.graphics.newCanvas(128, 400)
    self.silhouette_feather_cutout_canvas = love.graphics.newCanvas(128, 400)
    self.light_cutout_canvas = love.graphics.newCanvas(128, 400)

    self.spotlight_offset_x, self.spotlight_offset_y = target_battler.actor:getReviveSongSpotlightOffset()

    self:setLayer(target_battler.layer + 20)

    self.on_finish_func = settings.on_finish_func

    self.feathers = {}

    self.sparkles_timer = 0
end

function ReviveSongEffect:shouldShowSpamton()
    -- TODO: This condition is *really* weird and depends on DR flags which don't exist in (most) fangames
    -- The main thing is that this is disabled outside of chapter 5
    return false
end

function ReviveSongEffect:update()
    local old_timer = self.timer
    self.timer = self.timer + DTMULT

    if old_timer < 10 and self.timer >= 10 then
        Assets.playSound("sparkle_glock", 1, 1.1)

        local feather_x = self.x + self.spotlight_offset_x - 1
        local feather_y = self.y + self.spotlight_offset_y - 60 - 50

        local feather = Game.battle:addChild(CherubFeather(feather_x - 10, feather_y, -math.rad(270 + MathUtils.randomInt(-30, -50))))
        feather.layer = self.layer - 10
        table.insert(self.feathers, feather)

        feather = Game.battle:addChild(CherubFeather(feather_x, feather_y, -math.rad(270 + MathUtils.randomInt(-10, 10))))
        feather.layer = self.layer - 10
        table.insert(self.feathers, feather)

        feather = Game.battle:addChild(CherubFeather(feather_x + 10, feather_y, -math.rad(270 + MathUtils.randomInt(30, 50))))
        feather.layer = self.layer - 10
        table.insert(self.feathers, feather)
    end

    if self.timer >= 10 and self.timer <= 34 then
        if self.sparkles_timer <= 0 then
            self.sparkles_timer = self.sparkles_timer + 2

            local x = self.x + self.spotlight_offset_x
            local y = MathUtils.lerp(-5, self.y + self.spotlight_offset_y - 60 - 50, MathUtils.clamp((self.timer - 10) / 25, 0, 1))

            local offset = math.pi - 1

            local sparkles_a = Game.battle:addChild(Sprite("effects/spare/star", x + (math.cos((self.timer / 3) + offset) * 30), y + (math.sin((self.timer / 3) + offset) * 10)))
            sparkles_a:setScale(2)
            sparkles_a:setOrigin(6 / 13, 6 / 13)
            sparkles_a:play(2 / 30, false, function(sprite)
                sprite:remove()
            end)
            sparkles_a:setColor(TableUtils.pick({{ 1, 0.878431, 0.301961 }, { 1, 0.709804, 0.423529 }}))

            local sparkles_b = Game.battle:addChild(Sprite("effects/spare/star", x - (math.sin((self.timer / 3) + offset) * 30), y - (math.cos((self.timer / 3) + offset) * 10)))
            sparkles_b:setScale(2)
            sparkles_b:setOrigin(6 / 13, 6 / 13)
            sparkles_b:play(2 / 30, false, function(sprite)
                sprite:remove()
            end)
            sparkles_b:setColor(TableUtils.pick({{ 1, 0.878431, 0.301961 }, { 1, 0.709804, 0.423529 }}))
        end
        self.sparkles_timer = self.sparkles_timer - DTMULT
    end

    if old_timer < 34 and self.timer >= 34 then
        local anim_1 = "effects/cherub/ralsei"
        local anim_2 = "effects/cherub/ralsei"
        local anim_1_origin = { 0.5, 0.5 }
        local anim_2_origin = { 0.5, 0.5 }

        if self:shouldShowSpamton() then
            if MathUtils.randomInt(2) == 0 then
                anim_1 = "effects/cherub/spamton"
                anim_2 = "effects/cherub/ralsei_peeved"
                anim_1_origin = { 0.5, 11 / 23 }
            else
                anim_1 = "effects/cherub/ralsei_peeved"
                anim_2 = "effects/cherub/spamton"
                anim_2_origin = { 0.5, 11 / 23 }
            end
        end

        local spread = Utils.ease(0, 20, MathUtils.clamp(self.timer / 20, 0, 1), "in-out-quart")

        local animation_a = Game.battle:addChild(Sprite(anim_1, self.x + self.spotlight_offset_x + spread + 9, self.y + self.spotlight_offset_y - 98))
        animation_a:setScale(2)
        animation_a:setOrigin(unpack(anim_1_origin))
        animation_a:play(1 / 30, false, function(sprite)
            sprite:remove()
        end)

        local animation_b = Game.battle:addChild(Sprite(anim_2, self.x + self.spotlight_offset_x - spread - 11, self.y + self.spotlight_offset_y - 98))
        animation_b:setScale(-2, 2)
        animation_b:setOrigin(unpack(anim_2_origin))
        animation_b:play(1 / 30, false, function(sprite)
            sprite:remove()
        end)
    end

    if old_timer < 58 and self.timer >= 58 then
        if self.on_finish_func then
            self.on_finish_func(self)
        end
    end

    if self.timer >= 58 then
        self.alpha = self.alpha - 0.1 * DTMULT
        if self.alpha <= 0 then
            self:remove()
        end
    end

    super.update(self)
end

function ReviveSongEffect:drawEllipse(x1, y1, x2, y2)
    love.graphics.ellipse("fill", (x1 + x2) / 2, (y1 + y2) / 2, math.abs(x2 - x1) / 2, math.abs(y2 - y1) / 2)
end


function ReviveSongEffect:drawObject(object)
    love.graphics.push()
    object:preDraw()
    object:draw()
    object:postDraw()
    love.graphics.pop()
end

function ReviveSongEffect:drawCone(x, y, length, spread, direction, rounded)
    local half = math.rad(spread / 2)
    local dir = math.rad(direction)

    local left = dir - half
    local right = dir + half

    local x1 = x + math.cos(left) * length
    local y1 = y + math.sin(left) * length

    local x2 = x + math.cos(right) * length
    local y2 = y + math.sin(right) * length

    love.graphics.polygon("fill", x, y, x1, y1, x2, y2)

    if rounded then
        local cx = x + math.cos(dir) * length
        local cy = y + math.sin(dir) * length
        love.graphics.circle("fill", cx, cy, spread / 2)
    end
end

function ReviveSongEffect:draw()
    -- Clamp technically not needed, but...
    local spread = Utils.ease(0, 20, MathUtils.clamp(self.timer / 20, 0, 1), "in-out-quart")
    local length = 360 + (math.sin((spread / 180) * math.pi) * 20)
    local width = math.cos(-math.rad(270 + (spread / 2))) * length

    local draw_x = self.width / 2 + self.spotlight_offset_x
    local draw_y = self.height / 2 + self.spotlight_offset_y

    love.graphics.setColor(1, 0.811765, 0.427451, self.alpha / 2)

    love.graphics.ellipse("fill", draw_x, draw_y, width, width / 4)

    love.graphics.setColor(1, 1, 1)
    Draw.pushShader("AddColor", {
        inputcolor = {1, 0.709804, 0.423529},
        amount = 1
    })

    local old_alpha = self.target_battler.alpha
    local old_color = self.target_battler.color
    self.target_battler.alpha = spread * self.alpha

    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(0, -2)
    self:drawObject(self.target_battler)

    Draw.popShader()
    love.graphics.translate(0, 2)

    self.target_battler.color = { 0.501961, 0.47451, 0.462745 }
    self:drawObject(self.target_battler)
    love.graphics.pop()

    self.target_battler.alpha = old_alpha

    love.graphics.push()
    local tl_x, tl_y = self:getRelativePos(0, 0)
    love.graphics.translate(-tl_x, -tl_y)
    for _, feather in ipairs(self.feathers) do
        self:drawObject(feather)
    end
    love.graphics.pop()

    Draw.pushCanvas(self.silhouette_canvas)
    love.graphics.clear()
    love.graphics.origin()

    love.graphics.push()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.translate(-self.target_battler.x, -self.target_battler.y)
    love.graphics.translate(64 - self.spotlight_offset_x, 300 + (self.height / 2))
    love.graphics.translate(0, (60 - draw_y))
    love.graphics.translate(0, -2)
    self:drawObject(self.target_battler)
    love.graphics.translate(0, 2)
    love.graphics.setColor(0, 0, 0, 1)
    self:drawObject(self.target_battler)
    love.graphics.pop()

    self.target_battler.color = old_color

    Draw.popCanvas()

    Draw.pushCanvas(self.silhouette_feather_cutout_canvas)
    love.graphics.clear()
    love.graphics.origin()

    local major, _, _, _ = love.getVersion()

    local drawStencil = function()
        Draw.pushShader("Mask")

        for _, feather in ipairs(self.feathers) do
            love.graphics.push()
            love.graphics.translate(-self.target_battler.x, -self.target_battler.y)
            love.graphics.translate(64 - self.spotlight_offset_x, 300 + (self.height / 2))
            love.graphics.translate(0, (60 - draw_y))
            self:drawObject(feather)
            love.graphics.pop()
        end

        Draw.popShader()
    end

    if major >= 12 then
        love.graphics.clear(false, true, false)
        love.graphics.setStencilMode("draw", 1, "replace")

        drawStencil()

        love.graphics.setStencilMode("test", 0, "greater")
    else
        love.graphics.stencil(drawStencil, "replace", 1)

        love.graphics.setStencilTest("less", 1)
    end

    Draw.drawCanvas(self.silhouette_canvas)

    if major >= 12 then
        love.graphics.setStencilMode()
    else
        love.graphics.setStencilTest()
    end

    Draw.popCanvas()

    love.graphics.setBlendMode("alpha", "alphamultiply")

    Draw.pushCanvas(self.light_canvas)
    love.graphics.clear()
    love.graphics.origin()

    love.graphics.setColor(1, 1, 1)
    self:drawCone(64, 0, length, -spread, -270, false)
    love.graphics.ellipse("fill", 64, 360, width, width / 4)

    Draw.popShader()
    Draw.popCanvas()

    Draw.pushCanvas(self.light_cutout_canvas)
    love.graphics.clear()
    love.graphics.origin()

    local major, _, _, _ = love.getVersion()

    local drawStencil = function()
        Draw.pushShader("Mask")
        Draw.drawCanvas(self.silhouette_feather_cutout_canvas)
        Draw.popShader()
    end

    if major >= 12 then
        love.graphics.clear(false, true, false)
        love.graphics.setStencilMode("draw", 1, "replace")

        drawStencil()

        love.graphics.setStencilMode("test", 0, "greater")
    else
        love.graphics.stencil(drawStencil, "replace", 1)

        love.graphics.setStencilTest("less", 1)
    end

    Draw.drawCanvas(self.light_canvas)

    if major >= 12 then
        love.graphics.setStencilMode()
    else
        love.graphics.setStencilTest()
    end

    Draw.popCanvas()

    love.graphics.setColor(1, 0.709804, 0.423529, self.alpha * 0.5)
    love.graphics.draw(self.light_cutout_canvas, draw_x - 64, -300 - 60 + draw_y)

    super.draw(self)
end

return ReviveSongEffect
