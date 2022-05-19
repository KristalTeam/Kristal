local Interactable, super = Class(Event)

function Interactable:init(x, y, width, height, properties)
    super:init(self, x, y, width or TILE_WIDTH, height or TILE_HEIGHT)

    properties = properties or {}

    self.solid = properties["solid"] or false

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]
    self.text = Utils.parsePropertyMultiList("text", properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.once = properties["once"] or false

    self.interact_count = 0
end

function Interactable:getDebugInfo()
    local info = super:getDebugInfo(self)
    if self.cutscene  then table.insert(info, "Cutscene: "  .. self.cutscene)  end
    if self.script    then table.insert(info, "Script: "    .. self.script)    end
    if self.set_flag  then table.insert(info, "Set Flag: "  .. self.set_flag)  end
    if self.set_value then table.insert(info, "Set Value: " .. self.set_value) end
    table.insert(info, "Once: " .. (self.once and "True" or "False"))
    table.insert(info, "Text length: " .. #self.text)
    return info
end

function Interactable:onAdd(parent)
    super:onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Interactable:onInteract(player, dir)
    self.interact_count = self.interact_count + 1

    if self.script then
        Registry.getEventScript(self.script)(self, player, dir)
    end
    local cutscene
    if self.cutscene then
        cutscene = self.world:startCutscene(self.cutscene, self, player, dir)
    else
        cutscene = self.world:startCutscene(function(c)
            local text = self.text
            if type(text[self.interact_count]) == "table" then
                text = text[self.interact_count]
            end
            for _,line in ipairs(text) do
                c:text(line)
            end
        end)
    end
    cutscene:after(function()
        self:onTextEnd()
    end)

    if self.set_flag then
        Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
    end

    self:setFlag("used_once", true)
    if self.once then
        self:remove()
    end

    return true
end

function Interactable:onTextEnd() end

return Interactable