local Object = Class{}

Object.CHILD_SORTER = function(a, b) return a.layer < b.layer end

function Object:init(x, y, width, height)
    -- Intitialize this object's position (optional args)
    self.pos = Vector(x or 0, y or 0)

    -- Initialize this object's size
    self.width = width or 0
    self.height = height or 0

    -- Various draw properties
    self.color = {1, 1, 1, 1}
    self.scale = Vector(1, 1)
    self.rotation = 0
    
    -- Object scissor
    self.cutout = {left = 0, right = 0, top = 0, bottom = 0}
    
    -- Whether this object's color will be multiplied by its parent's color
    self.inherit_color = false

    -- Origin of the object's position
    self.origin = Vector(0, 0)
    -- Origin of the object's scaling
    self.scale_origin = Vector(0.5, 0.5)
    -- Origin of the object's rotation
    self.rotate_origin = Vector(0.5, 0.5)

    -- This object's sorting, higher number = renders last (above siblings)
    self.layer = 0

    -- Whether this object updates
    self.active = true

    -- Whether this object draws
    self.visible = true

    self.parent = nil
    self.children = {}
end

--[[ Common overrides ]]--

function Object:update(dt)
    self:updateChildren(dt)
end

function Object:draw()
    self:drawChildren()
end

function Object:onAdd(parent) end
function Object:onRemove(parent) end

--[[ Common functions ]]--

function Object:move(x, y)
    self.pos = self.pos + Vector(x or 0, y or x or 0)
end

function Object:moveTo(x, y)
    self.pos = Vector(x or 0, y or x or 0)
end

function Object:getScreenPos(x, y)
    x, y = x or 0, y or 0
    return self:getFullTransform():inverseTransformPoint(x, y)
end

function Object:getRelativePos(other, x, y)
    x, y = x or 0, y or 0
    local sx, sy = self:getFullTransform():transformPoint(x, y)
    return other:getFullTransform():inverseTransformPoint(sx, sy)
end

function Object:getSize()
    return Vector(self.width, self.height)
end

function Object:getStage()
    if self.parent and self.parent.parent then
        return self.parent:getStage()
    elseif self.parent then
        return self.parent
    end
end

function Object:getDrawColor()
    local r, g, b, a = unpack(self.color)
    if self.inherit_color and self.parent then
        local pr, pg, pb, pa = self.parent:getDrawColor()
        return r * pr, g * pg, b * pb, (a or 1) * (pa or 1)
    else
        return r, g, b, a or 1
    end
end

function Object:getTransform()
    local transform = love.math.newTransform()
    transform:translate(self.pos.x - self.width * self.origin.x, self.pos.y - self.height * self.origin.y)
    if self.scale ~= 1 then
        transform:translate(self.width * self.scale_origin.x, self.height * self.scale_origin.y)
        transform:scale(self.scale.x, self.scale.y)
        transform:translate(self.width * -self.scale_origin.x, self.height * -self.scale_origin.y)
    end
    if self.rotation ~= 0 then
        transform:translate(self.width * self.rotate_origin.x, self.height * self.rotate_origin.y)
        transform:rotate(self.rotation)
        transform:translate(self.width * -self.rotate_origin.x, self.height * -self.rotate_origin.y)
    end
    return transform
end

function Object:getFullTransform()
    if not self.parent then
        return self:getTransform()
    else
        return self.parent:getFullTransform() * self:getTransform()
    end
end

function Object:add(child)
    child.parent = self
    table.insert(self.children, child)
    self:sortChildren()
    child:onAdd(self)
end

function Object:remove(child)
    if child.parent == self then
        child.parent = nil
    end
    for i,v in ipairs(self.children) do
        if v == child then
            table.remove(self.children, i)
            break
        end
    end
    self:sortChildren()
    child:onRemove(self)
end

--[[ Internal functions ]]--

function Object:sortChildren()
    table.sort(self.children, Object.CHILD_SORTER)
end

function Object:updateChildren(dt)
    for _,v in ipairs(self.children) do
        if v.active then
            v:update(dt)
        end
    end
end

function Object:drawChildren()
    local oldr, oldg, oldb, olda = love.graphics.getColor()
    for _,v in ipairs(self.children) do
        if v.visible then
            love.graphics.push()
            love.graphics.applyTransform(v:getTransform())
            love.graphics.setColor(v:getDrawColor())
            local do_scissor = v.cutout.left ~= 0 or v.cutout.right ~= 0 or v.cutout.top ~= 0 or v.cutout.bottom ~= 0
            if do_scissor then
                kristal.graphics.pushScissor()
                kristal.graphics.scissor(v.cutout.left, v.cutout.top, v.width - v.cutout.right - v.cutout.left, v.height - v.cutout.bottom - v.cutout.top)
            end
            v:draw()
            if do_scissor then
                kristal.graphics.popScissor()
            end
            love.graphics.pop()
        end
    end
    love.graphics.setColor(oldr, oldg, oldb, olda)
end

return Object