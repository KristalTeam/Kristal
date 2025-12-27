--- Creates a region in the Overworld that reflects characters inside it. \
--- `MirrorArea` is an [`Event`](lua://Event.init) - naming an object `mirror` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object. \
--- To customise how mirror sprites are displayed, refer to [`Actor`](lua://Actor.init)s and their [`mirror_sprites`](lua://Actor.mirror_sprites) table and functions: [`getMirrorSprites`](lua://Actor.getMirrorSprites), [`getMirrorSprite`](lua://Actor.getMirrorSprite)
---@class MirrorArea : Event
---
---@field offset    number  *[Property `offset`]* The y-offset for reflections drawn in this mirror (Defaults to `0`)
---@field opacity   number  *[Property `opacity`]* The opacity of reflections drawn in the mirror (Defaults to `1`)
---
---@field bottom    number
---
---@overload fun(...) : MirrorArea
local MirrorArea, super = Class(Event)

function MirrorArea:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.offset = properties["offset"] or 0
    self.opacity = properties["opacity"] or 1

    self.bottom = self.y + self.height
end

--- Finds and draws all character's reflections
function MirrorArea:drawMirror()
    local to_draw = {}
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(Character) and obj.visible then
            table.insert(to_draw, 1, obj) -- always add to the start of the table, so they render in reverse layer order
        end
    end
    for _, obj in ipairs(to_draw) do
        self:drawCharacter(obj)
    end
end

--- Draws a character's reflection
---@param chara Character
function MirrorArea:drawCharacter(chara)
    love.graphics.push()

    chara:preDraw()
    local oyd = chara.y - self.bottom
    love.graphics.translate(0, -oyd + self.offset)
    local oldsprite = string.sub(chara.sprite.texture_path, #chara.sprite.path + 2)
    local t = Utils.split(oldsprite, "_")
    local pathless = ""
	for i=1, #t-1 do
		pathless = pathless .. "_" .. t[i]
	end
	pathless = string.sub(pathless, 2)
	local frame = t[#t]
    local newsprite = oldsprite
    local mirror = chara.actor:getMirrorSprites()
    if mirror and mirror[pathless] then
        if frame then
			newsprite = mirror[pathless] .. "_" .. frame
		end
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
