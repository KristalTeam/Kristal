local DialogueText = newClass(Object)

DialogueText.COLORS = {
    ["red"] = COLORS.red,
    ["blue"] = COLORS.blue,
    ["yellow"] = COLORS.yellow,
    ["green"] = COLORS.lime,
    ["white"] = COLORS.white,
    ["black"] = COLORS.black,
    ["purple"] = COLORS.purple,
    ["maroon"] = COLORS.maroon,
    ["pink"] = {1, 0.5, 1},
    ["lime"] = {0.5, 1, 0.5}
}

function DialogueText:init(text, x, y, font)
    super:init(self, x, y)

    self.font = font or "main"
    self.chars = {}
    self:setText(text)
end

function DialogueText:setText(text)
    for _,v in ipairs(self.chars) do
        self:remove(v)
    end
    self.chars = {}

    self.text = text

    local lines = utils.split(text, "\n")

    local height = 36 -- TODO: Font determined line spacing

    local color = {1, 1, 1, 1}
    local ypos = 0

    for _,line in ipairs(lines) do
        local xpos = 0
        local i = 1
        while i <= #line do
            local current_char = line:sub(i, i)
            if current_char == "[" then -- We got a [, time to see if it's a modifier
                local current_modifier = ""
                local j = i + 1
                while j <= #line do
                    if line:sub(j, j) == "]" then -- We found a bracket!
                        local old_i = i
                        i = j + 1 -- Let's set i so the modifier isn't processed as normal text

                        -- Let's split some values in the modifier!
                        local split = utils.splitFast(current_modifier, ":")
                        local command = split[1]
                        local arguments = utils.splitFast(split[2], ",")

                        if command == "color" then
                            if DialogueText.COLORS[arguments[1]] then
                                -- Did they input a valid color name? Let's use it.
                                color = utils.copy(DialogueText.COLORS[arguments[1]])
                            elseif arguments[1] == "reset" then
                                -- They want to reset the color.
                                color = {1, 1, 1, 1}
                            elseif #arguments[1] == 6 then
                                -- It's 6 letters long, assume hashless hex
                                color = utils.hexToRgb("#" .. arguments[1])
                            elseif #arguments[1] == 7 then
                                -- It's 7 letters long, assume hex
                                color = utils.hexToRgb(arguments[1])
                            else
                                -- We couldn't get a color, just give up and say it's an invalid modifier
                                i = old_i
                                break
                            end
                        else
                            -- Whoops, invalid modifier. Let's just parse this like normal text...
                            i = old_i
                        end

                        current_char = line:sub(i, i) -- Set current_char to the new value
                        break
                    else
                        current_modifier = current_modifier .. line:sub(j, j)
                    end
                    j = j + 1
                end
                -- It didn't find a closing bracket, let's give up
            end
            local char = DialogueChar(current_char, xpos, ypos, color)
            table.insert(self.chars, char)
            self:add(char)
            xpos = xpos + char.width

            i = i + 1
        end
        ypos = ypos + height
    end
end

return DialogueText