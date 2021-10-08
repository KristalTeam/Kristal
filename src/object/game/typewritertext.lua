local TypewriterText = newClass(Object)

function TypewriterText:init(text, x, y, font)
    super:init(self, x, y)

    self.font = font or "main"
    self.chars = {}

    self.dialogue_object = DialogueText("", x, y, font)

    self:setText(text)
end

function TypewriterText:setText(text)
    for _,v in ipairs(self.dialogue_object.chars) do
        self:remove(v)
    end

    self.text = text
    self.progress = 0

end

return TypewriterText