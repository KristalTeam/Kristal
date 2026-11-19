--- Visual tileset layout editing
---@class EditorTileLayoutInput : EditorControl
---@field columns number
---@field columns_input EditorTextInput
---@field count number
---@field count_input EditorTextInput
---@field grid_columns number
---@field grid_rows number
---@field hover_column number?
---@field hover_row number?
---@field inputs EditorTextInput[]
---@field on_changed function?
---@field preferred_height number
---@overload fun(value?: table, options?: table): EditorTileLayoutInput
local EditorTileLayoutInput, super = Class(EditorControl)

function EditorTileLayoutInput:init(value, options)
    options = options or {}
    super.init(self, 0, 0, options.width or 240, options.height or 154)
    self.preferred_height = options.height or 154
    self.grid_columns = options.grid_columns or 12
    self.grid_rows = options.grid_rows or 6
    self.on_changed = options.on_changed
    self.columns = 1
    self.count = 0
    self.columns_input = self:addChild(EditorTextInput({
        submit_feedback = false,
        on_submit = function(input)
            local columns = tonumber(input)
            if not columns or columns < 1 then
                self.columns_input:setValue(self.columns, true)
                return false
            end
            return self:setLayout(columns, self.count)
        end
    }))
    self.count_input = self:addChild(EditorTextInput({
        submit_feedback = false,
        on_submit = function(input)
            local count = tonumber(input)
            if not count or count < 0 then
                self.count_input:setValue(self.count, true)
                return false
            end
            return self:setLayout(self.columns, count)
        end
    }))
    self.inputs = { self.columns_input, self.count_input }
    self:setValue(value, true)
end

function EditorTileLayoutInput:setValue(value, silent)
    value = value or {}
    return self:setLayout(value.columns or 1, value.count or 0, silent)
end

function EditorTileLayoutInput:setLayout(columns, count, silent)
    columns = math.max(1, MathUtils.round(tonumber(columns) or 1))
    count = math.max(0, MathUtils.round(tonumber(count) or 0))
    local changed = columns ~= self.columns or count ~= self.count
    self.columns, self.count = columns, count
    self.columns_input:setValue(columns, true)
    self.count_input:setValue(count, true)
    if changed and not silent and self.on_changed then
        return self.on_changed({ columns = columns, count = count }, self) ~= false
    end
    return true
end

function EditorTileLayoutInput:getGridRect()
    local cell_size = math.max(6, math.min(14,
        math.floor(math.max(1, self.width - 2) / self.grid_columns),
        math.floor(math.max(1, self.height - 70) / self.grid_rows)))
    return 1, 70, cell_size, self.grid_columns * cell_size, self.grid_rows * cell_size
end

function EditorTileLayoutInput:getGridCellAt(x, y)
    local grid_x, grid_y, cell_size, grid_width, grid_height = self:getGridRect()
    if x < grid_x or y < grid_y or x >= grid_x + grid_width or y >= grid_y + grid_height then
        return nil
    end
    return math.floor((x - grid_x) / cell_size) + 1,
        math.floor((y - grid_y) / cell_size) + 1
end

function EditorTileLayoutInput:onMousePressed(x, y, button)
    if button ~= 1 then return false end
    local column, row = self:getGridCellAt(x, y)
    if not column then return false end
    return self:setLayout(column, column * row)
end

function EditorTileLayoutInput:onMouseMoved(x, y)
    self.hover_column, self.hover_row = self:getGridCellAt(x, y)
    return self.hover_column ~= nil
end

function EditorTileLayoutInput:getCursorType(x, y)
    return self:getGridCellAt(x, y) and "select" or "default"
end

function EditorTileLayoutInput:update(dt)
    local gap = 8
    local input_width = math.max(36, (self.width - gap) / 2)
    self.columns_input:setBounds(0, 18, input_width, 28)
    self.count_input:setBounds(input_width + gap, 18, input_width, 28)
    super.update(self, dt)
end

function EditorTileLayoutInput:drawSelf()
    love.graphics.setFont(EditorFont.get(14))
    Draw.setColor(0.68, 0.68, 0.72, 1)
    love.graphics.print("Columns", 0, 0)
    love.graphics.print("Tile Count", self.count_input.x, 0)
    Draw.setColor(0.55, 0.55, 0.60, 1)
    love.graphics.print("Click a cell to set a rectangular layout", 0, 51)

    local grid_x, grid_y, cell_size = self:getGridRect()
    for row = 1, self.grid_rows do
        for column = 1, self.grid_columns do
            local x = grid_x + (column - 1) * cell_size
            local y = grid_y + (row - 1) * cell_size
            local id = (row - 1) * self.columns + column
            local selected = column <= self.columns and id <= self.count
                and id > (row - 1) * self.columns
            local hovered = self.hover_column and column <= self.hover_column
                and row <= self.hover_row
            if selected then
                Draw.setColor(0.20, 0.48, 0.88, 0.48)
                love.graphics.rectangle("fill", x, y, cell_size, cell_size)
            end
            if hovered then
                Draw.setColor(0.92, 0.72, 0.25, 0.22)
                love.graphics.rectangle("fill", x, y, cell_size, cell_size)
            end
            Draw.setColor(0.31, 0.32, 0.37, 1)
            love.graphics.rectangle("line", x + 0.5, y + 0.5, cell_size - 1, cell_size - 1)
        end
    end
end

return EditorTileLayoutInput
