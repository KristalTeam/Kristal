---@class MirrorArea : Event
local MirrorArea, super = Class(Event)

function MirrorArea:init(x, y, w, h, properties)
    super.init(self, x, y, w, h)

    properties = properties or {}

    self.offset = properties["offset"] or 0
    self.opacity = properties["opacity"] or 1

    self.bottom = self.y + self.height
end

function MirrorArea:drawMirror()
    local to_draw = {}
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(Character) then
            table.insert(to_draw, 1, obj) -- always add to the start of the table, so they render in reverse layer order
        end
    end
    for _, obj in ipairs(to_draw) do
        self:drawCharacter(obj)
    end
end

function MirrorArea:drawCharacter(chara)
    love.graphics.push()

    chara:preDraw()
    local oyd = chara.y - self.bottom
    love.graphics.translate(0, -oyd + self.offset)
    local oldsprite = string.sub(chara.sprite.texture_path, #chara.sprite.path + 2)
    local t = Utils.split(oldsprite, "_")
    local pathless = t[1]
    local frame = t[2]
    local newsprite = oldsprite
    local mirror = chara.actor:getMirrorSprites()
    if mirror and mirror[pathless] then
        newsprite = mirror[pathless] .. "_" .. frame
    end
    chara.sprite:setTextureExact(chara.actor.path .. "/" .. newsprite)
    chara:draw()
    chara:postDraw()
    chara.sprite:setTextureExact(chara.actor.path .. "/" .. oldsprite)

    love.graphics.pop()
end

function MirrorArea:draw()
    super.draw(self)

    local canvas = Draw.pushCanvas(self.width, self.height)
    love.graphics.clear()
    love.graphics.translate(-self.x, -self.y)
    self:drawMirror()
    Draw.popCanvas()

    Draw.setColor(1, 1, 1, self.opacity)
    Draw.draw(canvas)
    Draw.setColor(1, 1, 1, 1)
end

return MirrorArea
