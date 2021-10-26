local Textbox, super = Class(Object)

function Textbox:init(x, y, width, height, no_background)
    super:init(self, x, y, width, height)

    self.box = DarkBox(0, 0, width, height)
    self.box.layer = -1
    self:addChild(self.box)

    if no_background then
        self.box.visible = false
    end

    self.face_x = 16 + 2
    self.face_y = 10 - 4

    self.text_x = 2
    self.text_y = -2

    self.face = Sprite()
    self.face.path = "face"
    self.face:setPosition(self.face_x, self.face_y)
    self.face:setScale(2, 2)
    self:addChild(self.face)

    self.text = DialogueText("", self.text_x, self.text_y, width, height)
    self.text.line_offset = 8 -- idk this is dumb
    self:addChild(self.text)
end

function Textbox:setSize(w, h)
    self.width, self.height = w or 0, h or 0

    self.face:setPosition(116 / 2, self.height /2)
    self.text:setSize(self.width, self.height)
    if self.face.texture then
        self.box:setSize(self.width - 116, self.height)
    else
        self.box:setSize(self.width, self.height)
    end
end

function Textbox:setFace(face, ox, oy)
    self.face:setSprite(face)
    self.face:setPosition(self.face_x + (ox or 0), self.face_y + (oy or 0))

    if self.face.texture then
        self.text.x = self.text_x + 116
        self.text.width = self.width - 116
    else
        self.text.x = self.text_x
        self.text.width = self.width
    end
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