---@class DarkConfigBorderState : StateClass
---
---@field menu DarkConfigMenu
---
---@overload fun(menu: DarkConfigMenu) : DarkConfigBorderState
local DarkConfigBorderState, super = Class(StateClass)

function DarkConfigBorderState:init(menu)
    self.menu = menu
end

function DarkConfigBorderState:registerEvents()
    self:registerEvent("update", self.onUpdate)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function DarkConfigBorderState:onUpdate()
    if Input.pressed("cancel") or Input.pressed("confirm") then
        self.menu:setState("MAIN")
        return
    end

    local types = Kristal.getBorderTypes()

    local border_index = -1
    for current_index, border in ipairs(types) do
        if border[1] == Kristal.Config["borders"] then
            border_index = current_index
        end
    end
    if border_index == -1 then
        border_index = 1
    end

    local old_index = border_index
    if Input.pressed("left") then
        border_index = math.max(border_index - 1, 1)
    end
    if Input.pressed("right") then
        border_index = math.min(border_index + 1, #types)
    end

    if old_index ~= border_index then
        Kristal.Config["borders"] = types[border_index][1]

        if types[border_index][1] == "off" then
            Kristal.resetWindow()
        elseif types[old_index][1] == "off" then
            Kristal.resetWindow()
        end
    end
end

return DarkConfigBorderState
