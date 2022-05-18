local ActionBox, super = Class(Object)

function ActionBox:init(x, y, index, battler)
    super:init(self, x, y)

    self.animation_timer = 0
    self.selection_siner = 0

    self.index = index
    self.battler = battler

    self.selected_button = 1

    self.revert_to = 40

    self.data_offset = 0

    self.box = ActionBoxDisplay(self)
    self.box.layer = 1
    self:addChild(self.box)

    self.head_offset_x, self.head_offset_y = battler.chara:getHeadIconOffset()

    self.head_sprite = Sprite(battler.chara:getHeadIcons().."/"..battler:getHeadIcon(), 13 + self.head_offset_x, 11 + self.head_offset_y)
    if not self.head_sprite:getTexture() then
        self.head_sprite:setSprite(battler.chara:getHeadIcons().."/head")
    end
    self.force_head_sprite = false

    if battler.chara:getNameSprite() then
        self.name_sprite = Sprite(battler.chara:getNameSprite(), 51, 14)
        self.box:addChild(self.name_sprite)
    end

    self.hp_sprite   = Sprite("ui/hp", 109, 22)

    self.box:addChild(self.head_sprite)
    self.box:addChild(self.hp_sprite)

    self:createButtons()
end

function ActionBox:getButtons(battler)
end

function ActionBox:createButtons()
    for _,button in ipairs(self.buttons or {}) do
        button:remove()
    end

    self.buttons = {}

    local btn_types = {"fight", "act", "magic", "item", "spare", "defend"}

    if not self.battler.chara:hasAct() then Utils.removeFromTable(btn_types, "act") end
    if not self.battler.chara:hasSpells() then Utils.removeFromTable(btn_types, "magic") end

    for lib_id,_ in pairs(Mod.libs) do
        btn_types = Kristal.libCall(lib_id, "getActionButtons", self.battler, btn_types) or btn_types
    end
    btn_types = Kristal.modCall("getActionButtons", self.battler, btn_types) or btn_types

    local start_x = (213 / 2) - ((#btn_types-1) * 35 / 2) - 1
    for i,btn in ipairs(btn_types) do
        if type(btn) == "string" then
            local button = ActionButton(btn, self.battler, math.floor(start_x + ((i - 1) * 35)) + 0.5, 21)
            button.actbox = self
            table.insert(self.buttons, button)
            self:addChild(button)
        else
            btn:setPosition(math.floor(start_x + ((i - 1) * 35)) + 0.5, 21)
            btn.battler = self.battler
            btn.actbox = self
            table.insert(self.buttons, btn)
            self:addChild(btn)
        end
    end

    self.selected_button = Utils.clamp(self.selected_button, 1, #self.buttons)
end

function ActionBox:setHeadIcon(icon)
    self.force_head_sprite = true
    self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/"..icon)
end

function ActionBox:resetHeadIcon()
    self.force_head_sprite = false
    self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon())
    if not self.head_sprite:getTexture() then
        self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/head")
    end
end

function ActionBox:update()
    if (Game.battle.current_selecting == self.index) then
        self.animation_timer = self.animation_timer + 1 * DTMULT
    else
        self.animation_timer = self.animation_timer - 1 * DTMULT
    end

    if self.animation_timer > 7 then
        self.animation_timer = 7
    end

    if (Game.battle.current_selecting ~= self.index) and (self.animation_timer > 3) then
        self.animation_timer = 3
    end

    if self.animation_timer < 0 then
        self.animation_timer = 0
    end

    self.selection_siner = self.selection_siner + 2 * DTMULT

    if Game.battle.current_selecting == self.index then
        self.box.y = -Ease.outCubic(self.animation_timer, 0, 32, 7)
    else
        self.box.y = -Ease.outCubic(3 - self.animation_timer, 32, -32, 3)
    end

    self.head_sprite.y = 11 - self.data_offset + self.head_offset_y
    if self.name_sprite then
        self.name_sprite.y = 14 - self.data_offset
    end
    self.hp_sprite.y   = 22 - self.data_offset

    local current_head = self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon()
    if not self.force_head_sprite and self.head_sprite.sprite ~= current_head then
        self.head_sprite:setSprite(current_head)
        if not self.head_sprite:getTexture() then
            self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/head")
        end
    end

    for i,button in ipairs(self.buttons) do
        if (Game.battle.current_selecting == self.index) then
            button.selectable = true
            button.hovered = (self.selected_button == i)
        else
            button.selectable = false
            button.hovered = false
        end
    end

    super:update(self)
end

function ActionBox:select()
    self.buttons[self.selected_button]:select()
end

function ActionBox:unselect()
    self.buttons[self.selected_button]:unselect()
end

function ActionBox:draw()
    self:drawSelectionMatrix()
    self:drawActionBox()

    super:draw(self)

    if not self.name_sprite then
        font = Assets.getFont("name")
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1, 1)

        local name = self.battler.chara:getName():upper()
        print(name)
        local spacing = 5 - name:len()

        local off = 0
        for i = 1, name:len() do
            local letter = name:sub(i, i)
            love.graphics.print(letter, self.box.x + 51 + off, self.box.y + 14 - self.data_offset - 1)
            off = off + font:getWidth(letter) + spacing
        end
    end
end

function ActionBox:drawActionBox()
    love.graphics.setColor(1, 1, 1, 1)

    if Game.battle.current_selecting == self.index then
        love.graphics.setColor(self.battler.chara:getColor())
    else
        love.graphics.setColor(0, 0, 0, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(1  , 2, 1,   37)
    love.graphics.line(212, 2, 212, 37)
    love.graphics.line(0  , 6, 213, 6 )
end

function ActionBox:drawSelectionMatrix()
    -- Draw the background of the selection matrix
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 2, 2, 209, 35)

    if Game.battle.current_selecting == self.index then
        local r,g,b,a = self.battler.chara:getColor()

        for i = 0, 11 do
            local siner = self.selection_siner + (i * (10 * math.pi))

            love.graphics.setLineWidth(2)
            love.graphics.setColor(r, g, b, a * math.sin(siner / 60))
            if math.cos(siner / 60) < 0 then
                love.graphics.line(1 - (math.sin(siner / 60) * 30) + 30, 0, 1 - (math.sin(siner / 60) * 30) + 30, 37)
                love.graphics.line(211 + (math.sin(siner / 60) * 30) - 30, 0, 211 + (math.sin(siner / 60) * 30) - 30, 37)
            end
        end

        love.graphics.setColor(1, 1, 1, 1)
    end
end

return ActionBox