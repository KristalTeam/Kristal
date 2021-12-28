local Stage, super = Class(Object)

function Stage:init(x, y, w, h)
    super:init(self, x, y, w, h)

    self.objects = {}
    self.objects_by_class = {}
    self.objects_to_remove = {}

    self.stage = self

    self.timer = Timer()
    self:addChild(self.timer)
end

function Stage:getObjects(class)
    if class then
        return self.objects_by_class[class] or {}
    else
        return self.objects
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
    if object.onAddToStage then
        object:onAddToStage(self)
    end
    for _,child in ipairs(object.children) do
        self:addToStage(child)
    end
end

function Stage:removeFromStage(object)
    table.insert(self.objects_to_remove, object)
    if object.stage == self then
        object.stage = nil
    end
    if object.onRemoveFromStage then
        object:onRemoveFromStage(self)
    end
    for _,child in ipairs(object.children) do
        self:removeFromStage(child)
    end
end

function Stage:update(dt)
    for _,object in ipairs(self.objects_to_remove) do
        Utils.removeFromTable(self.objects, object)
        for class,_ in pairs(object.__includes_all) do
            if class.__tracked ~= false and self.objects_by_class[class] then
                Utils.removeFromTable(self.objects_by_class[class], object)
            end
        end
    end
    self.objects_to_remove = {}
    super:update(self, dt)
end

function Stage:draw()
    love.graphics.push()
    love.graphics.applyTransform(self:getTransform())
    Draw.pushScissor()
    self:applyScissor()
    super:draw(self)
    Draw.popScissor()
    love.graphics.pop()
end

return Stage