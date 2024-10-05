---@class LightStatMenu : Object
---@overload fun(...) : LightStatMenu
local LightStatMenu, super = Class(Object)

function LightStatMenu:init()
    super.init(self, 212, 76, 298, 370)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")

    self.heart_sprite = Assets.getTexture("player/heart_menu")

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self:addChild(self.bg)
end

function LightStatMenu:update()
    if Input.pressed("cancel") then
        self.ui_move:stop()
        self.ui_move:play()
        Game.world.menu:closeBox()
        return
    end

    super.update(self)
end

function LightStatMenu:draw()
    love.graphics.setFont(self.font)
    Draw.setColor(PALETTE["world_text"])

    local chara = Game.party[1]

    Draw.print("\"" .. chara:getName() .. "\"", 4, 8)
    Draw.print("LV  "..chara:getLightLV(), 4, 68)
    Draw.print("HP  "..chara:getHealth().." / "..chara:getStat("health"), 4, 100)

    local exp_needed = math.max(0, chara:getLightEXPNeeded(chara:getLightLV() + 1) - chara:getLightEXP())

    Draw.print("AT  "..chara:getBaseStats()["attack"] .." ("..chara:getEquipmentBonus("attack") ..")", 4, 164)
    Draw.print("DF  "..chara:getBaseStats()["defense"].." ("..chara:getEquipmentBonus("defense")..")", 4, 196)
    Draw.print("EXP: "..chara:getLightEXP(),   172, 164)
    Draw.print("NEXT: "..exp_needed, 172, 196)

    local weapon_name = chara:getWeapon() and chara:getWeapon():getName() or "None"
    local armor_name = chara:getArmor(1) and chara:getArmor(1):getName() or "None"

    Draw.print("WEAPON: "..weapon_name, 4, 256)
    Draw.print("ARMOR: "..armor_name, 4, 288)

    Draw.print(Game:getConfig("lightCurrency"):upper()..": "..Game.lw_money, 4, 328)

    super.draw(self)
end

return LightStatMenu