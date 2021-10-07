local DialogText = newClass(Object)

DialogText.COLORS = {
    ["R"] = COLORS.red,
    ["B"] = COLORS.blue,
    ["Y"] = COLORS.yellow,
    ["G"] = COLORS.lime,
    ["W"] = COLORS.white,
    ["X"] = COLORS.black,
    ["P"] = COLORS.purple,
    ["M"] = COLORS.maroon,
    ["S"] = {1, 0.5, 1},
    ["V"] = {0.5, 1, 0.5},
    ["0"] = nil
}

function DialogText:init(text, x, y, font)
    super:init(self, x, y)

    self.font = font or "main"
    self.chars = {}
    self:setText(text)
end

function DialogText:setText(text)
    for _,v in ipairs(self.chars) do
        self:remove(v)
    end
    self.chars = {}

    self.text = text

    local lines = utils.split(text, "\n")

    local height = 36 -- TODO: Font determined line spacing

    local color = nil
    local ypos = 0
    for _,line in ipairs(lines) do
        local xpos = 0
        local i = 1
        while i <= #line do
            if line:sub(i, i+1) == "\\c" then
                i = i + 2
                color = DialogText.COLORS[line:sub(i, i)]
            else
                local char = DialogChar(line:sub(i, i), xpos, ypos, color)
                table.insert(self.chars, char)
                self:add(char)
                xpos = xpos + char:getWidth()
            end
            i = i + 1
        end
        ypos = ypos + height
    end
end

return DialogText