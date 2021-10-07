local Object = Class{}

Object.CHILD_SORTER = function(a, b) return a.layer < b.layer end

function Object:init(x, y)
    -- Intitialize this object's position (x,y args optional)
    self.x = x or 0
    self.y = y or 0

    -- Whether this object updates
    self.active = true

    -- Whether this object draws
    self.visible = true

    -- This object's sorting, higher number = renders last (above siblings)
    self.layer = 0

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
            love.graphics.push()
            love.graphics.translate(v.x, v.y)
            v:update(dt)
            love.graphics.pop()
        end
    end
end

function Object:drawChildren()
    for _,v in ipairs(self.children) do
        if v.visible then
            love.graphics.push()
            love.graphics.translate(v.x, v.y)
            v:draw()
            love.graphics.pop()
        end
    end
end

return Object