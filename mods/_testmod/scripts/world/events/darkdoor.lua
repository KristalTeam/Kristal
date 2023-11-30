local DarkDoor, super = Class(Event)

function DarkDoor:init(data)
    super.init(self, data.center_x, data.center_y, data.width, data.height)

    self:setOrigin(0.5, 0.5)
    self:setSprite("darkdoor_closed")
end

return DarkDoor