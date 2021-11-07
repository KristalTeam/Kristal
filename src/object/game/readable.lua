local Readable, super = Class(Event)

function Readable:init(data)
    super:init(self, data.center_x, data.center_y, data.width, data.height)

    self.solid = false

    self.data = data

    self:setOrigin(0.5, 0.5)
    self:setHitbox(0, 0, data.width, data.height)
end

function Readable:onInteract(player, dir)
    if self.data.properties.text then
        Cutscene.start(function()
            Cutscene.text(self.data.properties.text)
        end)
    elseif self.data.properties.text1 then
        Cutscene.start(function()
            local index = 1
            while self.data.properties["text" .. index] do
                Cutscene.text(self.data.properties["text" .. index])
                index = index + 1
            end
        end)
    else
        error("Attempt to interact with textless readable")
    end

    return true
end

return Readable