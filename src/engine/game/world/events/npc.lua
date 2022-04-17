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

    self.cutscene = properties["cutscene"] or properties["scene"]
    self.text = Readable.parseText(properties)
end

function NPC:onInteract(player, dir)
    if self.cutscene then
        self.world:startCutscene(self.cutscene, self, player, dir)
        return true
    elseif #self.text > 0 then
        self.world:startCutscene(function(cutscene)
            for _,line in ipairs(self.text) do
                cutscene:text(line)
            end
            self:onTextEnd()
        end)
        return true
    end
end

function NPC:onTextEnd() end

return NPC