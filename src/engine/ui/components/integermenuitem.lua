---@class IntegerMenuItemComponent : ListMenuItemComponent
---@overload fun(...) : IntegerMenuItemComponent
local IntegerMenuItemComponent, super = Class(ListMenuItemComponent)

---@param from integer
---@param to integer
---@param value integer
---@param on_changed? function
---@param options? table
function IntegerMenuItemComponent:init(from, to, value, on_changed, options)
    local index = 1
    local list = {}
    for i = from, to do
        table.insert(list, i)
        if i == value then
            index = #list
        end
    end
    super.init(self, list, index, on_changed, options)
end

function IntegerMenuItemComponent:updateSelected()
    self.text:setText(self.prefix .. self.list[self.value] .. self.suffix)
    if self.on_changed then
        self.on_changed(self.list[self.value])
    end
    self:reflow()
end

return IntegerMenuItemComponent
