--- An option for the [`DarkConfigMenu`](lua://DarkConfigMenu).
---
---@class DarkConfigOption : Object
---@overload fun(...) : DarkConfigOption
local DarkConfigOption, super = Class(Object)

---@param menu DarkConfigMenu
---@param name string
---@param callback fun(self:DarkConfigOption)?
function DarkConfigOption:init(menu, name, callback)
    super.init(self, 0, 0, 477, 35)

    self.font = Assets.getFont("main")

    self.heart_sprite = Assets.getTexture("player/heart")

    self.menu = menu

    self.name = name
    self.callback = callback

    self.hovered = false

    self.added = false

    self.text = self:addChild(Text(name, 88, 0, 301, 35))
    self.text:setColor(PALETTE["world_text"])
end

function DarkConfigOption:setAdded(added)
    self.added = added
end

function DarkConfigOption:onRemove(parent)
    super.onRemove(self, parent)

    if self.added then
        self.menu:removeOptionByChild(self)
    end
end

function DarkConfigOption:onStateChanged(old, new)
end

function DarkConfigOption:setHovered(hovered)
    self.hovered = hovered
end

function DarkConfigOption:onSelected()
    Assets.stopAndPlaySound("ui_select")

    if self.callback then
        self.callback(self)
    end
end

function DarkConfigOption:drawSoul()
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 63, 10)
end

function DarkConfigOption:draw()
    super.draw(self)

    if self.hovered then
        self:drawSoul()
    end
end

return DarkConfigOption
