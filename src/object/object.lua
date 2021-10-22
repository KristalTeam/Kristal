local Object = Class()

Object.LAYER_SORT = function(a, b) return a.layer < b.layer end

function Object:init(x, y, width, height)
    -- Intitialize this object's position (optional args)
    self.x = x or 0
    self.y = y or 0

    -- Initialize this object's size
    self.width = width or 0
    self.height = height or 0

    -- Various draw properties
    self.color = {1, 1, 1}
    self.alpha = 1
    self.scale_x = 1
    self.scale_y = 1
    self.rotation = 0
    self.flip_x = false
    self.flip_y = false
    
    -- Whether this object's color will be multiplied by its parent's color
    self.inherit_color = false

    -- Origin of the object's position
    self.origin_x = 0
    self.origin_y = 0
    -- Origin of the object's scaling
    self.scale_origin_x = nil
    self.scale_origin_y = nil
    -- Origin of the object's rotation
    self.rotate_origin_x = nil
    self.rotate_origin_y = nil

    -- Object scissor, no scissor when nil
    self.cutout_left = nil
    self.cutout_top = nil
    self.cutout_right = nil
    self.cutout_bottom = nil

    -- This object's sorting, higher number = renders last (above siblings)
    self.layer = 0

    -- Collision hitbox
    self.collider = nil

    -- Triggers list sort / child removal
    self.update_child_list = false
    self.children_to_remove = {}

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

function Object:move(x, y, speed)
    self.x = self.x + (x or 0) * (speed or 1)
    self.y = self.y + (y or 0) * (speed or 1)
end

function Object:collidesWith(other)
    if other and self.collider then
        if isClass(other) and other:includes(Object) then
            return other.collider and self.collider:collidesWith(other.collider) or false
        else
            return self.collider:collidesWith(other)
        end
    end
    return false
end

function Object:setPosition(x, y) self.x = x or 0; self.y = y or 0 end
function Object:getPosition() return self.x, self.y end

function Object:setSize(width, height) self.width = width or 0; self.height = height or width or 0 end
function Object:getSize() return self.width, self.height end

function Object:setScale(x, y) self.scale_x = x or 1; self.scale_y = y or x or 1 end
function Object:getScale() return self.scale_x, self.scale_y end

function Object:setColor(r, g, b, a) self.color = {r, g, b}; self.alpha = a or self.alpha end
function Object:getColor() return self.color[1], self.color[2], self.color[3], self.alpha end

function Object:setOrigin(x, y) self.origin_x = x or 0; self.origin_y = y or x or 0 end
function Object:getOrigin() return self.origin_x, self.origin_y end

function Object:setScaleOrigin(x, y) self.scale_origin_x = x; self.scale_origin_y = y or x end
function Object:getScaleOrigin() return self.scale_origin_x or self.origin_x, self.scale_origin_y or self.origin_y end

function Object:setRotateOrigin(x, y) self.rotate_origin_x = x; self.rotate_origin_y = y or x end
function Object:getRotateOrigin() return self.rotate_origin_x or self.origin_x, self.rotate_origin_y or self.origin_y end

function Object:getLayer() return self.layer end
function Object:setLayer(layer)
    self.layer = layer
    if self.parent then
        self.parent.child_layer_changed = true
    end
end

function Object:setCutout(left, top, right, bottom)
    self.cutout_left = left
    self.cutout_top = top
    self.cutout_right = right
    self.cutout_bottom = bottom
end
function Object:getCutout()
    return self.cutout_left, self.cutout_top, self.cutout_right, self.cutout_bottom
end

function Object:setScreenPos(x, y)
    if self.parent then
        self:setPosition(self.parent:getFullTransform():inverseTransformPoint(x or 0, y or 0))
    else
        self:setPosition(x, y)
    end
end
function Object:getScreenPos()
    if self.parent then
        return self.parent:getFullTransform():transformPoint(self.x, self.y)
    else
        return self.x, self.y
    end
end

function Object:localToScreenPos(x, y)
    return self:getFullTransform():transformPoint(x or 0, y or 0)
end

function Object:screenToLocalPos(x, y)
    return self:getFullTransform():inverseTransformPoint(x or 0, y or 0)
end

function Object:setRelativePos(other, x, y)
    local sx, sy = other:getFullTransform():inverseTransformPoint(x, y)
    local cx, cy = self:getFullTransform():transformPoint(sx, sy)
    self:setPosition(self:getTransform():inverseTransformPoint(cx, cy))
end
function Object:getRelativePos(other, x, y)
    if other == self.parent then
        return self:getTransform():transformPoint(x, y)
    else
        local sx, sy = self:getFullTransform():transformPoint(x or 0, y or 0)
        return other:getFullTransform():inverseTransformPoint(sx, sy)
    end
end

function Object:getStage()
    if self.parent and self.parent.parent then
        return self.parent:getStage()
    elseif self.parent then
        return self.parent
    end
end

function Object:getDrawColor()
    local r, g, b = unpack(self.color)
    if self.inherit_color and self.parent then
        local pr, pg, pb, pa = self.parent:getDrawColor()
        return r * pr, g * pg, b * pb, self.alpha
    else
        return r, g, b, self.alpha
    end
end

function Object:applyScissor()
    local left, top, right, bottom = self:getCutout()
    if left or top or right or bottom then
        Draw.scissorPoints(left, top, right and (self.width - right), bottom and (self.height - bottom))
    end
end

function Object:getTransform()
    Utils.pushPerformance("Object#getTransform")
    local transform = love.math.newTransform()
    transform:translate(self.x, self.y)
    if self.flip_x or self.flip_y then
        transform:scale(self.flip_x and -1 or 1, self.flip_y and -1 or 1)
    end
    transform:translate(-self.width * self.origin_x, -self.height * self.origin_y)
    if self.scale_x ~= 1 or self.scale_y ~= 1 then
        transform:translate(self.width * (self.scale_origin_x or self.origin_x), self.height * (self.scale_origin_y or self.origin_y))
        transform:scale(self.scale_x, self.scale_y)
        transform:translate(self.width * -(self.scale_origin_x or self.origin_x), self.height * -(self.scale_origin_y or self.origin_y))
    end
    if self.rotation ~= 0 then
        transform:translate(self.width * (self.rotate_origin_x or self.origin_x), self.height * (self.rotate_origin_y or self.origin_y))
        transform:rotate(self.rotation)
        transform:translate(self.width * -(self.rotate_origin_x or self.origin_x), self.height * -(self.rotate_origin_y or self.origin_y))
    end
    Utils.popPerformance()
    return transform
end

function Object:getFullTransform()
    if not self.parent then
        return self:getTransform()
    else
        return self.parent:getFullTransform():apply(self:getTransform())
    end
end

function Object:getHierarchy()
    local tbl = {self}
    if self.parent then
        for _,v in ipairs(self.parent:getHierarchy()) do
            table.insert(tbl, v)
        end
    end
    return tbl
end

function Object:remove()
    if self.parent then
        self.parent:removeChild(self)
    end
end

function Object:explode(x, y)
    if self.parent then
        local rx, ry = self:getRelativePos(self.parent, self.width/2 + (x or 0), self.height/2 + (y or 0))
        local e = Explosion(rx, ry)
        self.parent:addChild(e)
        self:remove()
    end
end

function Object:addChild(child)
    child.parent = self
    if self.stage and child.stage ~= self.stage then
        self.stage:addToStage(child)
    end
    table.insert(self.children, child)
    child:onAdd(self)
    self.update_child_list = true
end

function Object:removeChild(child)
    if child.parent == self then
        child.parent = nil
    end
    if self.stage and (not child.parent or not child.parent.stage) then
        self.stage:removeFromStage(child)
    end
    self.children_to_remove[child] = true
    self.update_child_list = true
end

--[[ Internal functions ]]--

function Object:sortChildren()
    table.sort(self.children, Object.LAYER_SORT)
end

function Object:updateChildList()
    for child,_ in pairs(self.children_to_remove) do
        for i,v in ipairs(self.children) do
            if v == child then
                child:onRemove(self)
                table.remove(self.children, i)
                break
            end
        end
    end
    self.children_to_remove = {}
    self:sortChildren()
end

function Object:updateChildren(dt)
    self:getFullTransform(true) -- Cache the current transformation
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _,v in ipairs(self.children) do
        if v.active then
            v:update(dt)
        end
    end
end

function Object:drawChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    local oldr, oldg, oldb, olda = love.graphics.getColor()
    for _,v in ipairs(self.children) do
        if v.visible then
            love.graphics.push()
            love.graphics.applyTransform(v:getTransform())
            love.graphics.setColor(v:getDrawColor())
            Draw.pushScissor()
            v:applyScissor()
            v:draw()
            Draw.popScissor()
            love.graphics.pop()
        end
    end
    love.graphics.setColor(oldr, oldg, oldb, olda)
end

return Object