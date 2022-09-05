local NPC, super = Class(Character)

function NPC:init(actor, x, y, properties)
    super:init(self, actor, x, y)

    properties = properties or {}

    if properties["sprite"] then
        self.sprite:setSprite(properties["sprite"])
    elseif properties["animation"] then
        self.sprite:setAnimation(properties["animation"])
    end

    self.start_facing = properties["facing"] or "down"

    if properties["facing"] then
        self:setFacing(properties["facing"])
    end

    self.turn = properties["turn"] or false

    self.talk = properties["talk"] ~= false

    self.solid = properties["solid"] == nil or properties["solid"]

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]
    self.text = Utils.parsePropertyMultiList("text", properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.interact_count = 0
end

function NPC:onInteract(player, dir)
    if self.turn then
        self:facePlayer()
    end
    self.interact_count = self.interact_count + 1

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
            cutscene:setSpeaker(self, self.talk)
            local text = self.text
            local text_index = Utils.clamp(self.interact_count, 1, #text)
            if type(text[text_index]) == "table" then
                text = text[text_index]
            end
            for _,line in ipairs(text) do
                cutscene:text(line)
            end
        end):after(function()
            self:onTextEnd()
        end)
        return true
    end
end

function NPC:onTextEnd()
    if self.turn then
        self:setFacing(self.start_facing)
    end
end

return NPC