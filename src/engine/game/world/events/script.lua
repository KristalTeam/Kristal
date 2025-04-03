--- Scripts are Overworld events that trigger immediately when the player steps into them. \
--- Naming an object `script` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---@class Script : Event
---
---@field solid     boolean
---
---@field cutscene  string  *[Property `cutscene`]* The name of a cutscene to start when this script is triggered
---@field script    string  *[Property `script`]* The name of a script file to run when this script is triggered
---
---@field set_flag  string  *[Property `setflag`]* The name of a flag to set the value of when this script is triggered 
---@field set_value any     *[Property `setvalue`]* The value to set on the flag specified by [`set_flag`](lua://Script.set_flag) (Defaults to `true`)
---
---@field once      boolean *[Property `once`]* Whether this script can only be triggered once per save file (Defaults to `true`)
---@field temp      boolean *[Property `temp`]* Whether the script is temporarily persistent - appears even if `once` is true and it has been triggered (Defaults to `false`)
---
---@overload fun(...) : Script
local Script, super = Class(Event)

function Script:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.solid = false

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.once = properties["once"] ~= false
    self.temp = properties["temp"] or false
end

function Script:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.cutscene  then table.insert(info, "Cutscene: "  .. self.cutscene)  end
    if self.script    then table.insert(info, "Script: "    .. self.script)    end
    if self.set_flag  then table.insert(info, "Set Flag: "  .. self.set_flag)  end
    if self.set_value then table.insert(info, "Set Value: " .. self.set_value) end
    table.insert(info, "Once: " .. (self.once and "True" or "False"))
    table.insert(info, "Temp: " .. (self.temp and "True" or "False"))
    return info
end

function Script:onAdd(parent)
    super.onAdd(self, parent)
    if self.once and not self.temp and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Script:onEnter(chara)
    if chara.is_player then
        if self.cutscene and self.world:hasCutscene() then
            return true
        end
        if self.script then
            Registry.getEventScript(self.script)(self, chara)
        end
        if self.cutscene then
            self.world:startCutscene(self.cutscene, self, chara)
        end
        if self.set_flag then
            Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
        end
        if self.once then
            self:setFlag("used_once", true)
            self:remove()
        end
        return true
    end
end

function Script:draw()
    super.draw(self)
    if DEBUG_RENDER then
        self.collider:draw(0, 1, 1)
    end
end

return Script