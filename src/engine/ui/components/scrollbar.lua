---@class ScrollbarComponent : Component
---@overload fun(...) : ScrollbarComponent
local ScrollbarComponent, super = Class(Component)

function ScrollbarComponent:init(options)
    options = options or {}

    -- fill, dotted, none
    self.gutter = options.gutter or "fill"

    local width = 4
    if self.gutter == "dotted" then
        width = 9
    end
    if options.arrows then
        width = 14
    end

    super.init(self, 0, 0, FixedSizing(options.width or width), FillSizing())

    self:setMargins(unpack(options.margins or {0, 0, 0, 0}))

    self.gutter_color = options.gutter_color or (self.gutter == "dotted" and COLORS.white or COLORS.dkgray)
    self.gutter_width = options.gutter_width or width
    self.color = options.color or COLORS.white

    self.arrows = options.arrows or false
    self:setOverflow("visible")
end

function ScrollbarComponent:onAdd(parent)
    self:updatePosition()
end

function ScrollbarComponent:update()
    super.update(self)
    self:updatePosition()
end

function ScrollbarComponent:reflow(ignore)
    super.reflow(self, ignore)
    self:updatePosition()
end

function ScrollbarComponent:updatePosition()
    if self.parent.getScrollbarPosition then
        self.x = self.parent:getScrollbarPosition()
        self.y = 0
    end
end

function ScrollbarComponent:draw()
    super.draw(self)
    -- calculate scrollbar size and position from parent
    local scrollbar_size = 0
    local scrollbar_position = 0

    local gutter_height = self.height
    local scrollbar_y = 0
    local scrollbar_x = 0

    if self.arrows then
        gutter_height = gutter_height - 60
        scrollbar_y = 24 + 6
        scrollbar_x = 2
    end

    scrollbar_size = self.parent:getTotalHeight() / self.parent:getInnerHeight() * gutter_height
    scrollbar_position = self.parent.scroll_y / self.parent:getInnerHeight() * gutter_height

    love.graphics.setColor(self.gutter_color)
    if self.gutter == "fill" then
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y, self.width, gutter_height)
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + scrollbar_position, self.width, scrollbar_size)
    elseif self.gutter == "none" then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + scrollbar_position, self.width, scrollbar_size)
    elseif self.gutter == "dotted" then
        -- get the amount of items
        local items = #self.parent:getMenuItems()

        for i = 1, items do
            local percentage = (i - 1) / (items - 1)
            local y = percentage * (gutter_height - 9)

            love.graphics.rectangle("fill", scrollbar_x + 3, scrollbar_y + 3 + y, 3, 3)
        end

        love.graphics.setColor(self.color)
        local percentage = (self.parent.selected_item - 1) / (items - 1)
        local y = percentage * (gutter_height - 9)

        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + y, 9, 9)
    end

    if self.arrows then
        local sine_off = math.sin((Kristal.getTime()*30)/6) * 3
        Draw.draw(Assets.getTexture("ui/page_arrow_down"), 0, 16 - sine_off + 4, 0, 1, -1)
        Draw.draw(Assets.getTexture("ui/page_arrow_down"), 0, self.height + sine_off - 16 - 4)
    end
end

return ScrollbarComponent
