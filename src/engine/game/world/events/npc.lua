local NPC, super = Class(Character)

function NPC:init(actor, x, y, properties)
    super:init(self, actor, x, y)

    properties = properties or {}

    if properties["sprite"] then
        self.sprite:set(properties["sprite"])
    end

    self.solid = properties["solid"] == nil or properties["solid"]

    self.cutscene = properties["script"]
    self.text = {}

    if properties["text"] then
        self.text = {properties["text"]}
    else
        local i = 1
        while properties["text"..i] do
            table.insert(self.text, properties["text"..i])
            i = i + 1
        end
    end
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