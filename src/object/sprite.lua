local Sprite = newClass(Object)

function Sprite:init(texture, x, y, allow_anim)
    super:init(self, x, y)

    if (allow_anim == nil or allow_anim) and kristal.data.getAnimation(texture) then
        self.animation = Animation(texture)
        self:updateTexture()
    else
        self:setTexture(texture)
    end
    self.speed = 1
end

function Sprite:updateTexture()
    if self.animation then
        self:setTexture(self.animation:getTexture(), true)
    end
end

function Sprite:setTexture(texture, keep_anim)
    if not keep_anim then
        self.animation = nil
    end
    if type(texture) == "string" then
        texture = kristal.assets.getTexture(texture)
    end
    self.texture = texture
    self.width = self.texture:getWidth()
    self.height = self.texture:getHeight()
end

function Sprite:setAnimation(animation, play)
    if type(animation) == "string" then
        self.animation = Animation(animation, play)
    else
        self.animation = animation
    end
    self:updateTexture()
end

function Sprite:play(anim, reset)
    self.animation:play(anim, reset)
    self:updateTexture()
end

function Sprite:stop()
    self.animation:stop()
end

function Sprite:pause()
    self.animation:pause()
end

function Sprite:update(dt)
    if self.animation then
        self.animation.speed = self.speed
        self.animation:update(dt)
        self:updateTexture()
    end

    super:update(self, dt)
end

function Sprite:draw()
    love.graphics.draw(self.texture)

    super:draw(self)
end

return Sprite