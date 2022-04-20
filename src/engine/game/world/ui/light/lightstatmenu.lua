local LightStatMenu, super = Class(Object)

function LightStatMenu:init()
    super:init(self, 212, 76, 298, 370)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")

    self.heart_sprite = Assets.getTexture("player/heart_menu")

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self:addChild(self.bg)
end

function LightStatMenu:update(dt)
    if Input.pressed("cancel") then
        self.ui_move:stop()
        self.ui_move:play()
        Game.world.menu:closeBox()
        return
    end

    super:update(self, dt)
end

function LightStatMenu:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.print("\"" .. Game.party[1]:getName() .. "\"", 4, 8)
    love.graphics.print("LV  1", 4, 68)
    love.graphics.print("HP  20 / 20", 4, 100)

    love.graphics.print("AT  10 (1)", 4,   164)
    love.graphics.print("DF  10 (0)", 4,   196)
    love.graphics.print("EXP: 0",   172, 164)
    love.graphics.print("NEXT: 10", 172, 196)

    local weapon_name = Game.party[1]:getWeapon() and Game.party[1]:getWeapon():getName() or "None"
    local armor_name = Game.party[1]:getArmor(1) and Game.party[1]:getArmor(1):getName() or "None"

    love.graphics.print("WEAPON: "..weapon_name, 4, 256)
    love.graphics.print("ARMOR: "..armor_name, 4, 288)

    love.graphics.print("MONEY: 2", 4, 328)

    super:draw(self)
end

return LightStatMenu