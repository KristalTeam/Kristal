---@class Stage : Object
---@overload fun(...) : Stage
local Stage, super = Class(Object)

function Stage:init(x, y, w, h)
    super.init(self, x, y, w, h)

    self.objects = {}
    self.objects_by_class = {}
    self.objects_to_remove = {}

    self.stage = self

    self.full_updating = false
    self.full_drawing = false

    self.timer = Timer()
    self:addChild(self.timer)
end

function Stage:getObjects(class)
    if class then
        return Utils.filter(self.objects_by_class[class] or {}, function(o) return o.stage == self end)
    else
        return Utils.filter(self.objects, function(o) return o.stage == self end)
    end
end

function Stage:addToStage(object)
    table.insert(self.objects, object)
    for class,_ in pairs(object.__includes_all) do
        if class.__tracked ~= false then
            self.objects_by_class[class] = self.objects_by_class[class] or {}
            table.insert(self.objects_by_class[class], object)
        end
    end
    object.stage = self
    object:onAddToStage(self)
    for _,child in ipairs(object.children) do
        self:addToStage(child)
    end
end

function Stage:updateAllLayers()
    for _,object in ipairs(self.objects) do
        if object.update_child_list or object.__index == World then
            object:updateChildList()
            object.update_child_list = false
        end
    end
end

function Stage:removeFromStage(object)
    table.insert(self.objects_to_remove, object)
    if object.stage == self then
        object.stage = nil
    end
    object:onRemoveFromStage(self)
    for _,child in ipairs(object.children) do
        self:removeFromStage(child)
    end
end

function Stage:update()
    if not self.active then return end

    if not self.full_updating then
        self.full_updating = true
        self:fullUpdate()
        self.full_updating = false
    else
        for _,object in ipairs(self.objects_to_remove) do
            Utils.removeFromTable(self.objects, object)
            for class,_ in pairs(object.__includes_all) do
                if class.__tracked ~= false and self.objects_by_class[class] then
                    Utils.removeFromTable(self.objects_by_class[class], object)
                end
            end
        end
        self.objects_to_remove = {}
        super.update(self)
    end
end

function Stage:draw()
    if not self.visible then return end

    if not self.full_drawing then
        CURRENT_SCALE_X = 1
        CURRENT_SCALE_Y = 1

        self.full_drawing = true
        self:fullDraw()
        self.full_drawing = false
    else
        super.draw(self)
    end
    --[[love.graphics.push()
    love.graphics.applyTransform(self:getTransform())
    Draw.pushScissor()
    self:applyScissor()
    super.draw(self)
    Draw.popScissor()
    love.graphics.pop()]]
end

function Stage:canDeepCopy()
    return false
end

return Stage