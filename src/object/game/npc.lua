local NPC, super = Class(Character)

function NPC:init(data)
    super:init(self, data.properties["actor"], data.center_x, data.center_y)

    self.solid = data.properties["solid"] == nil or data.properties["solid"]
    self.cutscene = data.properties["script"]
end

function NPC:onInteract(player, dir)
    if self.cutscene then
        Cutscene.start(self.cutscene)

        return true
    end
end

return NPC