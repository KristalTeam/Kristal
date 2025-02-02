---@class ModListLine : Object
---@overload fun(list: ModList, x:number,y:number,w:number): ModListLine
local ModListLine, super = Class(Object)

---@param list ModList
function ModListLine:init(list,x,y,w,h)
    super.init(self,x,y,w,(h or 0)+ 10)
    self.mod_list_width = 0
    self.list = list
    self.mods = {}
    ---@type SmallModButton?
    self.selected_mod = nil
end

function ModListLine:canAddMod(mod)
    return (self.mod_list_width + mod.width) <= self.width
end

---@param mod SmallModButton
function ModListLine:addMod(mod)
    table.insert(self.mods, mod)
    self:addChild(mod)
    mod:setPosition(self.mod_list_width, 0)
    self.mod_list_width = self.mod_list_width + (mod.width) + 8.5
    if (self.selected_mod == nil) and (#self.list.mods < 1) then
        self.selected_mod = mod
        self.mod = self.selected_mod and self.selected_mod.mod
        self.selected_mod:onSelect()
    end
end

function ModListLine:onSelect()
    self.selected_mod = self.mods[self.list.selected_x or 1]
    if not self.selected_mod then
        self.list.selected_x = #self.mods
        self.selected_mod = self.mods[self.list.selected_x or 1]
    end
    self.selected_mod:onSelect()
end

function ModListLine:select(i, mute)
    local last_selected = self.list.selected_x
    self.list.selected_x = i
    if last_selected ~= self.list.selected_x then
        if not mute then
            Assets.stopAndPlaySound("ui_move")
        end
        if self.mods[last_selected] then
            self.mods[last_selected]:onDeselect()
        end
        if self.mods[self.list.selected_x] then
            self.selected_mod = self.mods[self.list.selected_x]
            self.mods[self.list.selected_x]:onSelect()
        end
        return true
    end
end

function ModListLine:update()
    super.update(self)
    self.mod = self.selected_mod and self.selected_mod.mod or self.mod
end

function ModListLine:onDeselect()
    if self.selected_mod then
        self.selected_mod:onDeselect()
    end
end
function ModListLine:getHeartPos()
    if not self.selected_mod then return 0,0 end
    local x, y = self.selected_mod:getPosition()
    local ox, oy = self.selected_mod:getHeartPos()
    return x+ox, y+oy
end

return ModListLine