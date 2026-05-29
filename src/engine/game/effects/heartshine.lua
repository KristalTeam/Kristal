---@class HeartShine : Object
---@overload fun(...) : HeartShine
local HeartShine, super = Class(Object)

function HeartShine:init(x, y, properties)
    super.init(self, x, y)
    
    properties = properties or {}

    if type(properties["origin"]) == "table" then
        self:setOrigin(properties["origin"][1], properties["origin"][2])
    else
        self:setOrigin(properties["origin"] or 0.5)
    end
    
    if type(properties["scale"]) == "table" then
        self:setScale(properties["scale"][1], properties["scale"][2])
    else
        self:setScale(properties["scale"] or 2)
    end

    self.layer = properties["layer"] or (BATTLE_LAYERS["battlers"] + 1)

    self.background = Sprite(properties["background_sprite"] or "player/heart_shine_bg")
    self:setSize(self.background:getSize())
    self.background:play(properties["speed"] or 1 / 30, false, function() self:remove() end)
    self.background:setColor(ColorUtils.unpackColor(properties["background_color"] or COLORS.white))
    self:addChild(self.background)

    self.heart = Sprite(properties["sprite"] or "player/heart_shine")
    local r, g, b, a = ColorUtils.unpackColor(properties["color"] or {Game:getSoulColor()})
    self.heart:setColor(r, g, b, a)

    -- add an outline to the heart if the 'outline' parameter is undefined and the heart is purely white
    if properties["outline"] == nil and r == 1 and g == 1 and b == 1 and a > 0 then outline = true end
    if properties["outline"] then
        self.heart:addFX(OutlineFX(properties["outline_color"] or { 0, 0, 0 }))
    end
    self:addChild(self.heart)

    -- set the frame of the heart to the index of the background frame
    self.heart_frame = properties["sprite_frame_index"] or { false, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 1 }
end

function HeartShine:draw()
    local heart_frame = self.heart_frame[self.background.frame]
    if heart_frame then
        self.heart.visible = true
        self.heart:setFrame(heart_frame)
    else
        self.heart.visible = false
    end

    super.draw(self)
end

return HeartShine
