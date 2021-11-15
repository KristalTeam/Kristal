local NPC, super = Class(Character)

function NPC:init(data)
    super:init(self, data.properties["actor"], data.center_x, data.center_y)

    self.solid = data.properties["solid"] == nil or data.properties["solid"]

    self.cutscene = data.properties["script"]
    self.text = {}

    if data.properties["text"] then
        self.text = {data.properties["text"]}
    else
        local i = 1
        while data.properties["text"..i] do
            table.insert(self.text, data.properties["text"..i])
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

return NPC