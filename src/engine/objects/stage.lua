--- The Stage object in Kristal is designed to be the highest parent object at all times. \
--- All throughout gameplay, the active stage is [`Game.stage`](lua://Game.stage), while when in the Kristal menu, [`Kristal.Stage`](lua://Kristal.Stage) is the stage instead.
---
---@class Stage : Object
---@
---@field objects           Object[]                A list of all the objects attached to this stage
---@field objects_by_class  table<Class, Object[]>  A list of all the objects attached to this stage, sorted by the classes that they include
---@field objects_to_remove Object[]                A list of objects pending removal from this stage (removed on the next update tick)
---@
---@field stage Stage
---@
---@field full_updating boolean
---@field full_drawing boolean
---@
---@overload fun(x?: number, y?: number, w?: number, h?: number) : Stage
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

--- Gets every object attached to this stage that inherits from `class`
---@generic T : Class
---@param class T       The included Class to select from
---@return T[] matches  All the objects parented to this stage that inherit from `class`
function Stage:getObjects(class)
    if class then
        return Utils.filter(self.objects_by_class[class] or {}, function(o) return o.stage == self end)
    else
        return Utils.filter(self.objects, function(o) return o.stage == self end)
    end
end

--- Adds an object and all of its children to this stage
---@param object Object
function Stage:addToStage(object)
    if not isClass(object) or not object:includes(Object) then
        error("Cannot add non-Object to stage")
    end
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

--- Removes an object and all of its children from this stage
---@param object Object
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
