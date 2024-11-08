---@class ImageBorder: Border
---@overload fun(texture:love.Image|string, id?: string): ImageBorder
local ImageBorder, super = Class(Border)

function ImageBorder:init(texture, path)
    super.init(self)
    if type(texture) == "string" then
        texture = Assets.getTexture("borders/"..texture)
        path = texture
    end
    self.texture = texture
    self.id = path
end

function ImageBorder:draw()
    super.draw(self)
    Draw.draw(self.texture, 0, 0, 0, BORDER_SCALE)
end

return ImageBorder