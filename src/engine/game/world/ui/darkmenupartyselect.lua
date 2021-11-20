local DarkMenuPartySelect, super = Class(Object)

function DarkMenuPartySelect:init(x, y)
    super:init(self, x, y)

    self.focused = false

    self.selected_party = 1

    self.on_select = nil

    self.heart_siner = 0
end

function DarkMenuPartySelect:getSelected()
    return Game.party[self.selected_party]
end

function DarkMenuPartySelect:updateSelectedParty()
    self.selected_party = (self.selected_party - 1) % #Game.party + 1
end

function DarkMenuPartySelect:update(dt)
    self.heart_siner = self.heart_siner + DTMULT

    if self.focused then
        local old_selected = self.selected_party
        if Input.pressed("left") then
            self.selected_party = self.selected_party - 1
        elseif Input.pressed("right") then
            self.selected_party = self.selected_party + 1
        end
        self:updateSelectedParty()
        if old_selected ~= self.selected_party then
            Assets.stopAndPlaySound("ui_move")
            if self.on_select then
                self.on_select(self.selected_party, old_selected)
            end
        end
    end

    for i,action_box in pairs(Game.world.healthbar.action_boxes) do
        if i == self.selected_party then
            action_box.selected = true
        else
            action_box.selected = false
        end
    end

    super:update(self, dt)
end

function DarkMenuPartySelect:draw()
    for i,party in ipairs(Game.party) do
        if self.selected_party ~= i then
            love.graphics.setColor(1, 1, 1, 0.4)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        local ox, oy = 0, 0
        if party.menu_icon_offset then
            ox = party.menu_icon_offset[1] or 0
            oy = party.menu_icon_offset[2] or 0
        end
        love.graphics.draw(Assets.getTexture(party.menu_icon), (i-1)*50 + (ox*2), oy*2, 0, 2, 2)
    end
    if self.focused then
        local frames = Assets.getFrames("player/heart_harrows")
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(frames[(math.floor(self.heart_siner/20)-1)%#frames+1], (self.selected_party-1)*50 + 10, -18)
    end
    super:draw(self)
end

return DarkMenuPartySelect