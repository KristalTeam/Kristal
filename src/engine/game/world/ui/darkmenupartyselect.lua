local DarkMenuPartySelect, super = Class(Object)

function DarkMenuPartySelect:init(x, y)
    super:init(self, x, y)

    self.focused = false

    self.selected_party = 1

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
        if old_selected ~= self.selected_party then
            Assets.stopAndPlaySound("ui_move")
        end
        self:updateSelectedParty()
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
        love.graphics.draw(Assets.getTexture(party.menu_icon), (i-1)*50, 0, 0, 2, 2)
    end
    if self.focused then
        local frames = Assets.getFrames("player/heart_harrows")
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(frames[(math.floor(self.heart_siner/20)-1)%#frames+1], (self.selected_party-1)*50 + 10, -18)
    end
    super:draw(self)
end

return DarkMenuPartySelect