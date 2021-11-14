local Readable, super = Class(Event)

function Readable:init(x, y, width, height, text)
    text = text or {}

    if type(x) == "table" then
        local data = x
        x, y, width, height = data.center_x, data.center_y, data.width, data.height

        if data.properties["text"] then
            text = {data.properties["text"]}
        else
            local i = 1
            while data.properties["text"..i] do
                table.insert(text, data.properties["text"..i])
                i = i + 1
            end
        end
    end

    super:init(self, x, y, width, height)

    self.solid = false

    self.text = text

    self:setOrigin(0.5, 0.5)
    self:setHitbox(0, 0, self.width, self.height)
end

function Readable:onInteract(player, dir)
    Cutscene.start(function()
        for _,line in ipairs(self.text) do
            Cutscene.text(line)
        end
        self:onTextEnd()
    end)
    return true
end

function Readable:onTextEnd() end

function Readable:draw()
    super:draw(self)
    if DEBUG_RENDER then
        self.collider:draw(1, 0, 1)
    end
end

return Readable