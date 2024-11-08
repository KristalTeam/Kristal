---@class ImageBorder: Border
---@field texture love.Image # The texture to be drawn behind the game. Usually 1920x1080.
---@overload fun(texture:love.Image, id?: string): ImageBorder
---@overload fun(id: string): ImageBorder
local ImageBorder, super = Class(Border)

function ImageBorder:init(texture, path)
    super.init(self)
    if type(texture) == "string" then
        path = texture
        texture = Assets.getTexture("borders/"..texture)
    end
    self.texture = texture
    self.id = path
end

function ImageBorder:draw()
    super.draw(self)
    Draw.draw(self.texture, 0, 0, 0, BORDER_SCALE)
end

return ImageBorder