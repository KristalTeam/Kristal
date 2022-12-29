---@class SmallFaceText : Object
---@overload fun(...) : SmallFaceText
local SmallFaceText, super = Class(Object)

function SmallFaceText:init(text, x, y, face, actor)
    super.init(self, x, y)

    self.alpha = 0

    if face and face ~= "" then
        self.sprite = Sprite(face, 40, 0, nil, nil, actor and actor:getPortraitPath() or "")
        self.sprite.inherit_color = true
        self:addChild(self.sprite)
    end

    self.text = Text("", 40+70, 10, {wrap = false, font_size = 16})
    self.text.inherit_color = true
    self.text:setText(text)
    self:addChild(self.text)
end

function SmallFaceText:update()
    if self.alpha < 1 then
        self.alpha = Utils.approach(self.alpha, 1, 0.2*DTMULT)
    end
    if self.sprite and self.sprite.x > 0 then
        self.sprite.x = Utils.approach(self.sprite.x, 0, 10*DTMULT)
    end
    if self.text.x > 70 then
        self.text.x = Utils.approach(self.text.x, 70, 10*DTMULT)
    end
    super.update(self)
end

return SmallFaceText