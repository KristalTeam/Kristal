local Textbox, super = Class(Object)

function Textbox:init(x, y, width, height, battle_box)
    super:init(self, x, y, width, height)

    self.box = DarkBox(0, 0, width, height)
    self.box.layer = -1
    self:addChild(self.box)

    self.battle_box = battle_box
    if battle_box then
        self.box.visible = false
    end

    if battle_box then
        self.face_x = -4
        self.face_y = 2

        self.text_x = 0
        self.text_y = 0
    else
        self.face_x = 18
        self.face_y = 6

        self.text_x = 2
        self.text_y = -2
    end

    self.actor = nil

    self.face = Sprite()
    self.face.path = "face"
    self.face:setPosition(self.face_x, self.face_y)
    self.face:setScale(2, 2)
    self:addChild(self.face)

    self.text = DialogueText("", self.text_x, self.text_y, width, height)
    self.text.line_offset = 8 -- idk this is dumb
    self:addChild(self.text)

    self.auto_advance = false
end

function Textbox:update(dt)
    if not self.battle_box or BattleScene.isActive() then
        if Input.pressed("confirm") or self.auto_advance or Input.down("menu") then
            if not self:isTyping() then
                if not self.battle_box then
                    self:remove()
                    Cutscene.resume()
                elseif self.text.text ~= "" then
                    self:setText("")
                    BattleScene.resume()
                end
            end
        end
    end
    super:update(self, dt)
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

function Textbox:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.getActor(actor)
    end
    self.actor = actor

    if self.actor and self.actor.portrait_path then
        self.face.path = self.actor.portrait_path
    else
        self.face.path = "face"
    end
end

function Textbox:setFace(face, ox, oy)
    self.face:setSprite(face)

    if self.actor and self.actor.portrait_offset then
        ox = (ox or 0) + self.actor.portrait_offset[1]
        oy = (oy or 0) + self.actor.portrait_offset[2]
    end
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
    if self.actor and self.actor.text_sound then
        self.text:setText("[voice:"..self.actor.text_sound.."]"..text)
    else
        self.text:setText(text)
    end
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