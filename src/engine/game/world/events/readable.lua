local Readable, super = Class(Event)

function Readable:init(text, x, y, width, height)
    super:init(self, x, y, width or TILE_WIDTH, height or TILE_HEIGHT)

    self.solid = false

    self.text = text or {}
end

function Readable:onInteract(player, dir)
    self.world:startCutscene(function(cutscene)
        for _,line in ipairs(self.text) do
            cutscene:text(line)
        end
    end):after(function()
        self:onTextEnd()
    end)
    return true
end

function Readable:onTextEnd() end

function Readable.parseText(properties)
    properties = properties or {}
    if properties["text"] then
        return {properties["text"]}
    else
        local text = {}
        local i = 1
        while properties["text"..i] do
            table.insert(text, properties["text"..i])
            i = i + 1
        end
        return text
    end
end

return Readable