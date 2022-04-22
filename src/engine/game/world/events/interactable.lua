local Interactable, super = Class(Event)

function Interactable:init(x, y, width, height, properties)
    super:init(self, x, y, width or TILE_WIDTH, height or TILE_HEIGHT)

    properties = properties or {}

    self.solid = properties["solid"] or false

    self.cutscene = properties["cutscene"]
    self.text = Interactable.parseText(properties)

    self.once = properties["once"] or false
end

function Interactable:onAdd(parent)
    super:onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Interactable:onInteract(player, dir)
    local cutscene
    if self.cutscene then
        cutscene = self.world:startCutscene(self.cutscene, self, player, dir)
    else
        cutscene = self.world:startCutscene(function(c)
            for _,line in ipairs(self.text) do
                c:text(line)
            end
        end)
    end
    cutscene:after(function()
        self:onTextEnd()
    end)

    self:setFlag("used_once", true)
    if self.once then
        self:remove()
    end

    return true
end

function Interactable:onTextEnd() end

function Interactable.parseText(properties)
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

return Interactable