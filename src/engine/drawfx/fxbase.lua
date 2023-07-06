---@alias DrawFX FXBase
---@class FXBase : Class
---@overload fun(...) : FXBase
local FXBase = Class()

FXBase.SORTER = function(a, b) return (a.transformed and not b.transformed) or (a.transformed == b.transformed and a.priority > b.priority) end

function FXBase:init(priority)
    -- Identifier for this FX
    self.id = nil
    -- Object this FX is attached to
    self.parent = nil

    -- Higher number = higher priority (processed last)
    self.priority = priority or 0

    -- Whether this FX should be processed
    self.active = true

    -- Whether this FX should be transformed by the object (scaled, rotated, etc)
    -- Note: This will always have lower priority than non-transformed FX
    self.transformed = false
end

function FXBase:isActive()
    return self.active
end

function FXBase:update() end

function FXBase:draw(texture)
    -- Draw the canvas
    Draw.drawCanvas(texture)
end

function FXBase:getObjectBounds(shader)
    if not self.transformed then
        Object.startCache()
        local x1,y1 = self.parent:localToScreenPos(0, 0)
        local x2,y2 = self.parent:localToScreenPos(self.parent.width, 0)
        local x3,y3 = self.parent:localToScreenPos(self.parent.width, self.parent.height)
        local x4,y4 = self.parent:localToScreenPos(0, self.parent.height)
        Object.endCache()

        x1,y1 = math.floor(x1), math.floor(y1)
        x2,y2 = math.floor(x2), math.floor(y2)
        x3,y3 = math.floor(x3), math.floor(y3)
        x4,y4 = math.floor(x4), math.floor(y4)

        local x, y = math.min(x1,x2,x3,x4), math.min(y1,y2,y3,y4)
        local w, h = math.max(x1,x2,x3,x4) - x, math.max(y1,y2,y3,y4) - y

        if shader then
            return x/SCREEN_WIDTH, y/SCREEN_HEIGHT, w/SCREEN_WIDTH, h/SCREEN_HEIGHT
        else
            return x, y, w, h
        end
    else
        return SCREEN_WIDTH/2 - (self.parent.width/2), SCREEN_HEIGHT/2 - (self.parent.height/2), self.parent.width, self.parent.height
    end
end

function FXBase:canDeepCopy()
    return true
end
function FXBase:canDeepCopyKey(key)
    return key ~= "parent"
end

return FXBase