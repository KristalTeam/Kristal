local Object = Class{}

Object.CHILD_SORTER = function(a, b) return a.layer < b.layer end

function Object:init(x, y)
    -- Intitialize this object's position (optional args)
    self.pos = Vector(x or 0, y or 0)

    -- Initialize this object's size
    self.width = 0
    self.height = 0

    -- Various draw properties
    self.color = {1, 1, 1, 1}
    self.scale = Vector(1, 1)
    self.rotation = 0

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
            local r, g, b, a = unpack(v.color)
            love.graphics.setColor(r, g, b, a or 1)
            love.graphics.translate(v.pos.x - v.width * v.origin.x, v.pos.y - v.height * v.origin.y)
            if v.scale ~= 1 then
                love.graphics.translate(v.width * v.scale_origin.x, v.height * v.scale_origin.y)
                love.graphics.scale(v.scale.x, v.scale.y)
                love.graphics.translate(v.width * -v.scale_origin.x, v.height * -v.scale_origin.y)
            end
            if v.rotation ~= 0 then
                love.graphics.translate(v.width * v.rotate_origin.x, v.height * v.rotate_origin.y)
                love.graphics.rotate(v.rotation)
                love.graphics.translate(v.width * -v.rotate_origin.x, v.height * -v.rotate_origin.y)
            end
            v:draw()
            love.graphics.pop()
        end
    end
    love.graphics.setColor(oldr, oldg, oldb, olda)
end

return Object