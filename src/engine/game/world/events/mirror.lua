local Mirror, super = Class(Event, "mirror")

function Mirror:init(data)
    super:init(self, data.x, data.y, data.width, data.height)
	
	properties = data.properties or {}

    self.solid = false

    self.canvas = love.graphics.newCanvas(data.width, data.height)
	
	self.offset = properties and properties["offset"] or 0
	self.opacity = properties and properties["opacity"] or 1
	
	self.bottom = data.y + data.height
end

function Mirror:drawCharacter(object)
	love.graphics.push()
        local last_scale_y = object.scale_y
	object:preDraw()
	local oyd = object.y - self.bottom
	love.graphics.translate(0, -oyd + self.offset)
	local oldsprite = string.sub(object.sprite.texture_path, #object.sprite.path + 2)
	local t = self:split(oldsprite,"_")
	local pathless = t[1]
	local frame = t[2]
	local newsprite = oldsprite
	local mirror = object.actor.mirror
	local change = false
	if mirror then
		for key, val in pairs(mirror) do
			if key == pathless then
				newsprite = val .. "_" .. frame
				object.sprite.flip_x = true
				change = true
			end
		end
	end
	if change then
	        object.sprite.flip_x = true
	end
	object.sprite:setTextureExact(object.actor.path .. "/" .. newsprite)
	object:draw()
	object:postDraw()
	object.sprite:setTextureExact(object.actor.path .. "/" .. oldsprite)
	object.sprite.flip_x = false
	object.scale_y = last_scale_y
	love.graphics.pop()
end

function Mirror:draw()
    super:draw(self)

    Draw.pushCanvas(self.canvas)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then
			self:drawCharacter(object)

            love.graphics.setShader()
        end
    end

    Draw.popCanvas()
	love.graphics.setColor(1, 1, 1, self.opacity)
    love.graphics.draw(self.canvas)
    love.graphics.setColor(1, 1, 1, 1)
end

function Mirror:split(str, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for s in string.gmatch(str, "([^"..sep.."]+)") do
		table.insert(t, s)
	end
	return t
end

return Mirror
