---@class UIBox : Object
---@overload fun(...) : UIBox
local UIBox, super = Class(Object)

function UIBox:init(x, y, width, height, skin)
    super.init(self, x, y, width, height)

    self.left_frame   = 0
    self.top_frame    = 0
    self.corner_frame = 0

    self.skin = skin or Kristal.callEvent(KRISTAL_EVENT.getUISkin) or (Game:isLight() and "light" or "dark")
    self.fill_color = {0,0,0}

    self.left   = Assets.getFramesOrTexture("ui/box/" .. self.skin .. "/left")
    self.top    = Assets.getFramesOrTexture("ui/box/" .. self.skin .. "/top")
    self.corner = Assets.getFramesOrTexture("ui/box/" .. self.skin .. "/corner")

    self.corners = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}

    self.speed = 10
end

function UIBox:getBorder()
    return self.left[1]:getWidth()*2, self.top[1]:getHeight()*2
end

function UIBox:getDebugRectangle()
    if not self.debug_rect then
        local bw, bh = self:getBorder()
        return {-bw, -bh, self.width + bw*2, self.height + bh*2}
    end
    return super.getDebugRectangle(self)
end

function UIBox:draw()
    self.left_frame   = ((self.left_frame   + (DTMULT / self.speed)) - 1) % #self.left   + 1
    self.top_frame    = ((self.top_frame    + (DTMULT / self.speed)) - 1) % #self.top    + 1
    self.corner_frame = ((self.corner_frame + (DTMULT / self.speed)) - 1) % #self.corner + 1

    local left_width  = self.left[1]:getWidth()
    local left_height = self.left[1]:getHeight()
    local top_width   = self.top[1]:getWidth()
    local top_height  = self.top[1]:getHeight()

    local  r, g, b,a = self:getDrawColor()
    local fr,fg,fb   = unpack(self.fill_color)
    Draw.setColor(fr,fg,fb,a)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    Draw.setColor(r, g, b, a)

    Draw.draw(self.left[math.floor(self.left_frame)], 0, 0, 0, 2, self.height / left_height, left_width, 0)
    Draw.draw(self.left[math.floor(self.left_frame)], self.width, 0, math.pi, 2, self.height / left_height, left_width, left_height)

    Draw.draw(self.top[math.floor(self.top_frame)], 0, 0, 0, self.width / top_width, 2, 0, top_height)
    Draw.draw(self.top[math.floor(self.top_frame)], 0, self.height, math.pi, self.width / top_width, 2, top_width, top_height)

    for i = 1, 4 do
        local cx, cy = self.corners[i][1] * self.width, self.corners[i][2] * self.height
        local sprite = self.corner[math.floor(self.corner_frame)]
        local width  = 2 * ((self.corners[i][1] * 2) - 1) * -1
        local height = 2 * ((self.corners[i][2] * 2) - 1) * -1
        Draw.draw(sprite, cx, cy, 0, width, height, sprite:getWidth(), sprite:getHeight())
    end

    super.draw(self)
end

return UIBox