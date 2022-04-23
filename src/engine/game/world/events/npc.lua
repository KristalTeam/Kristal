local NPC, super = Class(Character)

function NPC:init(actor, x, y, properties)
    super:init(self, actor, x, y)

    properties = properties or {}

    if properties["sprite"] then
        self.sprite:setSprite(properties["sprite"])
    elseif properties["animation"] then
        self.sprite:setAnimation(properties["animation"])
    end

    if properties["facing"] then
        self:setFacing(properties["facing"])
    end

    self.solid = properties["solid"] == nil or properties["solid"]

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]
    self.text = Interactable.parseText(properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]
end

function NPC:onInteract(player, dir)
    if self.script then
        Registry.getEventScript(self.script)(self, player, dir)
    end
    if self.set_flag then
        Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
    end
    if self.cutscene then
        self.world:startCutscene(self.cutscene, self, player, dir):after(function()
            self:onTextEnd()
        end)
        return true
    elseif #self.text > 0 then
        self.world:startCutscene(function(cutscene)
            cutscene:setSpeaker(self, true)
            for _,line in ipairs(self.text) do
                cutscene:text(line)
            end
        end):after(function()
            self:onTextEnd()
        end)
        return true
    end
end

function NPC:onTextEnd() end

return NPC