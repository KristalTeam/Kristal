local Textbox, super = Class(Object)

function Textbox:init(x, y, width, height, no_background)
    super:init(self, x, y, width, height)

    self.box = DarkBox(0, 0, width, height)
    self.box.layer = -1
    self:addChild(self.box)

    if no_background then
        self.box.visible = false
    end

    self.face = Sprite()
    self.face.path = "face"
    self.face.y = height / 2
    self.face:setOrigin(0, 0.5)
    self.face:setScale(2, 2)
    self:addChild(self.face)

    self.text = DialogueText("", 0, 0, width, height)
    self.text.line_offset = 8 -- idk this is dumb
    self:addChild(self.text)
end

function Textbox:setSize(w, h)
    self.width, self.height = w or 0, h or 0

    self.box:setSize(self.width, self.height)
    self.text:setSize(self.width, self.height)
    self.face.y = self.height/2
end

function Textbox:setFace(face)
    self.face:setSprite(face)

    self.text.x = self.face.width * 2
    self.text.width = self.width - self.face.width * 2
end

function Textbox:setText(text)
    self.text:setText(text)
end

function Textbox:getBorder()
    if self.box.visible then
        return self.box:getBorder()
    else
        return 0, 0
    end
end

function Textbox:isTyping()
    return self.text.state.typing
end

return Textbox