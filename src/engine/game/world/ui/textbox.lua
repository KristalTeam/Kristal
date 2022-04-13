local Textbox, super = Class(Object)

Textbox.REACTION_X = {
        ["left"] = 70  -38,
     ["leftmid"] = 160 -38,
         ["mid"] = 260 -38,
      ["middle"] = 260 -38,
    ["rightmid"] = 360 -38,
       ["right"] = 400 -38,
}
Textbox.REACTION_Y = {
          ["top"] = -10 -4,
          ["mid"] =  30 -4,
       ["middle"] =  30 -4,
    ["bottommid"] =  50 -4,
       ["bottom"] =  68 -4,
}

Textbox.REACTION_X_BATTLE = {
        ["left"] = 60  -40,
     ["leftmid"] = 160 -40,
         ["mid"] = 260 -40,
      ["middle"] = 260 -40,
    ["rightmid"] = 360 -40,
       ["right"] = 460 -40,
}
Textbox.REACTION_Y_BATTLE = {
          ["top"] = -10 -2,
          ["mid"] =  30 -2,
       ["middle"] =  30 -2,
    ["bottommid"] =  45 -2,
       ["bottom"] =  56 -2,
}

function Textbox:init(x, y, width, height, default_font, default_font_size, battle_box)
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

    self.default_font = default_font or "main_mono"
    self.default_font_size = default_font_size

    self.font = self.default_font
    self.font_size = self.default_font_size

    self.face = Sprite()
    self.face.path = "face"
    self.face:setPosition(self.face_x, self.face_y)
    self.face:setScale(2, 2)
    self:addChild(self.face)

    self.text = DialogueText("", self.text_x, self.text_y, width, height)
    self.text.line_offset = 8 -- idk this is dumb
    self:addChild(self.text)

    self.reactions = {}
    self.reaction_instances = {}

    self.text:registerCommand("face", function(text, node)
        if self.actor and self.actor.portrait_path then
            self.face.path = self.actor.portrait_path
        end
        self:setFace(node.arguments[1], tonumber(node.arguments[2]), tonumber(node.arguments[3]))
    end)
    self.text:registerCommand("facec", function(text, node)
        self.face.path = "face"
        local ox, oy = tonumber(node.arguments[2]), tonumber(node.arguments[3])
        if self.actor and self.actor.portrait_offset then
            ox = (ox or 0) - self.actor.portrait_offset[1]
            oy = (oy or 0) - self.actor.portrait_offset[2]
        end
        self:setFace(node.arguments[1], ox, oy)
    end)

    self.text:registerCommand("react", function(text, node)
        local react_data = tonumber(node.arguments[1]) and self.reactions[tonumber(node.arguments[1])] or self.reactions[node.arguments[1]]
        local reaction = SmallFaceText(react_data.text, react_data.face, react_data.x, react_data.y, react_data.actor)
        reaction.layer = 0.1 + (#self.reaction_instances) * 0.01
        self:addChild(reaction)
        table.insert(self.reaction_instances, reaction)
    end, false)

    self.can_advance = not self.battle_box
    self.auto_advance = false
    self.done = false
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
        actor = Registry.createActor(actor)
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

function Textbox:setFont(font, size)
    if not font then
        self.font = self.default_font
        self.font_size = self.default_font_size
    else
        self.font = font
        self.font_size = size
    end
end

function Textbox:setSkippable(skippable)
    self.text.skippable = skippable or false
end

function Textbox:resetReactions()
    self.reactions = {}
    for _,reaction in ipairs(self.reaction_instances) do
        reaction:remove()
    end
    self.reaction_instances = {}
end

function Textbox:addReaction(id, actor, face, x, y, text)
    x, y = x or 0, y or 0
    if type(x) == "string" then
        x = self.battle_box and self.REACTION_X_BATTLE[x] or self.REACTION_X[x]
    end
    if type(y) == "string" then
        y = self.battle_box and self.REACTION_Y_BATTLE[y] or self.REACTION_Y[y]
    end
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    self.reactions[id] = {
        text = text,
        x = x,
        y = y,
        face = face,
        actor = actor
    }
end

function Textbox:resetFunctions()
    self.text.functions = {}
end

function Textbox:addFunction(id, func)
    self.text:addFunction(id, func)
end

function Textbox:setText(text)
    for _,reaction in ipairs(self.reaction_instances) do
        reaction:remove()
    end
    self.reaction_instances = {}
    self.text.font = self.font
    self.text.font_size = self.font_size
    callback = (function()
        self.done = true
        if not self.battle_box then
            self:remove()
            if Game.world:hasCutscene() and Game.world.cutscene.waiting_for_text == self then
                Game.world.cutscene.waiting_for_text = nil
                Game.world.cutscene:resume()
            end
        elseif self.text.text ~= "" then
            self:setText("")
            self:setActor()
            self:setFace()
            if Game.battle:hasCutscene() and Game.battle.cutscene.waiting_for_text == self then
                Game.battle.cutscene.waiting_for_text = nil
                Game.battle.cutscene:resume()
            end
        end
    end)
    if self.actor and self.actor.voice then
        self.text:setText("[voice:"..self.actor.voice.."]"..text, callback)
    else
        self.text:setText(text, callback)
    end
end

function Textbox:getText()
    return self.text.text
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