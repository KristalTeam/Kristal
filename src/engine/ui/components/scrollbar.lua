---@class ScrollbarComponent : Component
---@field parent AbstractMenuComponent
---@field gutter
---| '"fill"' The gutter will be filled in.
---| '"dotted"' The scrollbar will be dotted.
---| '"none"' The gutter will not be drawn.
---@field arrows boolean
---@field gutter_color table
---@field scrollbar_width number
---@field color table
---@overload fun(...) : ScrollbarComponent
local ScrollbarComponent, super = Class(Component)

---@param options? table
function ScrollbarComponent:init(options)
    options = options or {}

    -- fill, dotted, none
    self.gutter = options.gutter or "fill"
    self.arrows = options.arrows

    local min_width = 1
    if self.gutter == "dotted" then
        min_width = 9
    end
    if self.arrows then
        min_width = 14
    end

    local width = math.max(min_width, options.width or 6)

    super.init(self, FixedSizing(width), FillSizing(), options)

    self:setMargins(unpack(options.margins or {0, 0, 0, 0}))

    self.gutter_color = options.gutter_color or (self.gutter == "dotted" and COLORS.white or COLORS.dkgray)
    self.scrollbar_width = options.scrollbar_width or options.width or 6
    self.color = options.color or COLORS.white
    self:setOverflow("visible")
end

---@param parent Object
function ScrollbarComponent:onAdd(parent)
    self:updatePosition()
end

function ScrollbarComponent:update()
    super.update(self)
    self:updatePosition()
end

---@param ignore Component The component to ignore while reflowing. 
function ScrollbarComponent:reflow(ignore)
    super.reflow(self, ignore)
    if self:isRemoved() then return end

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
    local scrollbar_x = math.floor((self.width / 2) - (self.scrollbar_width / 2))

    if self.arrows then
        gutter_height = gutter_height - 60
        scrollbar_y = 24 + 6
    end

    scrollbar_size = self.parent:getTotalHeight() / self.parent:getInnerHeight() * gutter_height
    scrollbar_position = self.parent.scroll_y / self.parent:getInnerHeight() * gutter_height

    love.graphics.setColor(self.gutter_color)
    if self.gutter == "fill" then
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y, self.scrollbar_width, gutter_height)
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + scrollbar_position, self.scrollbar_width, scrollbar_size)
    elseif self.gutter == "none" then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + scrollbar_position, self.scrollbar_width, scrollbar_size)
    elseif self.gutter == "dotted" then
        -- get the amount of items
        local items = #self.parent:getMenuItems()

        for i = 1, items do
            local percentage = (i - 1) / (items - 1)
            local x = math.floor((self.width / 2) - (3 / 2))
            local y = percentage * (gutter_height - 9)
            love.graphics.rectangle("fill", x, scrollbar_y + 3 + y, 3, 3)
        end

        love.graphics.setColor(self.color)
        local percentage = (self.parent.selected_item - 1) / (items - 1)
        local x = math.floor((self.width / 2) - (9 / 2))
        local y = percentage * (gutter_height - 9)

        love.graphics.rectangle("fill", x, scrollbar_y + y, 9, 9)
    end

    if self.arrows then
        local arrow_x = math.floor((self.width / 2) - (13 / 2))
        local sine_off = math.sin((Kristal.getTime()*30)/6) * 3
        Draw.draw(Assets.getTexture("ui/page_arrow_down"), arrow_x, 16 - sine_off + 4, 0, 1, -1)
        Draw.draw(Assets.getTexture("ui/page_arrow_down"), arrow_x, self.height + sine_off - 16 - 4)
    end
end

return ScrollbarComponent
