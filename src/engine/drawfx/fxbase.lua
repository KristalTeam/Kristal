local FXBase = Class()

FXBase.SORTER = function(a, b) return a.priority > b.priority end

function FXBase:init(priority)
    -- Identifier for this FX
    self.id = nil
    -- Object this FX is attached to
    self.parent = nil

    -- Higher number = higher priority (processed last)
    self.priority = priority or 0

    -- Whether this FX should be processed
    self.active = true
end

function FXBase:isActive()
    return self.active
end

function FXBase:update(dt) end

function FXBase:draw(texture)
    -- Draw the canvas
    love.graphics.drawCanvas(texture)
end

function FXBase:getObjectBounds()
    Object.startCache()
    local x1,y1 = self.parent:localToScreenPos(0, 0)
    local x2,y2 = self.parent:localToScreenPos(self.parent.width, 0)
    local x3,y3 = self.parent:localToScreenPos(self.parent.width, self.parent.height)
    local x4,y4 = self.parent:localToScreenPos(0, self.parent.height)
    Object.endCache()

    local x, y = math.min(x1,x2,x3,x4), math.min(y1,y2,y3,y4)
    local w, h = math.max(x1,x2,x3,x4) - x, math.max(y1,y2,y3,y4) - y

    return x/SCREEN_WIDTH, y/SCREEN_HEIGHT, w/SCREEN_WIDTH, h/SCREEN_HEIGHT
end

return FXBase