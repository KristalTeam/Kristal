local DarkMenu, super = Class(Object)

function DarkMenu:init()
    super:init(self, 0, -80)

    self.layer = 1 -- TODO

    self.parallax_x = 0
    self.parallax_y = 0

    self.animation_done = false
    self.animation_timer = 0
    self.animate_out = false

    self.selected_submenu = 1

    -- States: MAIN, ITEMMENU, ITEMSELECT, KEYSELECT, PARTYSELECT,
    -- EQUIPMENU, WEAPONSELECT, REPLACEMENTSELECT, POWERMENU, SPELLSELECT,
    -- CONFIGMENU, VOLUMESELECT, CONTROLSMENU, CONTROLSELECT
    self.state = "MAIN"
    self.heart_sprite = Assets.getTexture("player/heart")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")

    self.font = Assets.getFont("main")

    self.desc_sprites = {
        Assets.getTexture("ui/menu/desc/item"),
        Assets.getTexture("ui/menu/desc/equip"),
        Assets.getTexture("ui/menu/desc/power"),
        Assets.getTexture("ui/menu/desc/config")
    }

    self.buttons = {
        {Assets.getTexture("ui/menu/btn/item"  ), Assets.getTexture("ui/menu/btn/item_h"  ), Assets.getTexture("ui/menu/btn/item_s"  )},
        {Assets.getTexture("ui/menu/btn/equip" ), Assets.getTexture("ui/menu/btn/equip_h" ), Assets.getTexture("ui/menu/btn/equip_s" )},
        {Assets.getTexture("ui/menu/btn/power" ), Assets.getTexture("ui/menu/btn/power_h" ), Assets.getTexture("ui/menu/btn/power_s" )},
        {Assets.getTexture("ui/menu/btn/config"), Assets.getTexture("ui/menu/btn/config_h"), Assets.getTexture("ui/menu/btn/config_s")}
    }
end

function DarkMenu:transitionOut()
    self.animate_out = true
    self.animation_timer = 0
    self.animation_done = false
end

function DarkMenu:keypressed(key)
    if Input.isMenu(key) and self.state == "MAIN" then
        Game.world:closeMenu()
        return
    end

    if not self.animation_done then return end

    if self.state == "MAIN" then
        local old_selected = self.selected_submenu
        if Input.is("left", key) then self.selected_submenu = self.selected_submenu - 1 end
        if Input.is("right", key) then self.selected_submenu = self.selected_submenu + 1 end
        if self.selected_submenu < 1 then self.selected_submenu = 4 end
        if self.selected_submenu > 4 then self.selected_submenu = 1 end
        if old_selected ~= self.selected_submenu then
            self.ui_move:stop()
            self.ui_move:play()
        end
    end
end

function DarkMenu:update(dt)
    self.animation_timer = self.animation_timer + (dt * 30)

    local max_time = self.animate_out and 3 or 8

    if self.animation_timer > max_time + 1 then
        self.animation_done = true
        self.animation_timer = max_time + 1
        if self.animate_out then
            Game.world.menu = nil
            self:remove()
            return
        end
    end

    local offset
    if not self.animate_out then
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), -80, 80, max_time)
    else
        self.y = Ease.outCubic(math.min(max_time, self.animation_timer), 0, -80, max_time)
    end

    super:update(self, dt)
end

function DarkMenu:draw()
    -- Draw the black background
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, 640, 80)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.desc_sprites[self.selected_submenu], 20, 24, 0, 2, 2)

    self:drawButton(1, 120, 20)
    self:drawButton(2, 220, 20)
    self:drawButton(3, 320, 20)
    self:drawButton(4, 420, 20)

    love.graphics.setFont(self.font)
    love.graphics.print("D$ " .. Game.gold, 520, 20)

    super:draw(self)
end

function DarkMenu:drawButton(index, x, y)
    local sprite = 1
    if index == self.selected_submenu then
        sprite = 2
        if self.state ~= "MAIN" then
            sprite = 3
        end
    end
    love.graphics.draw(self.buttons[index][sprite], x, y, 0, 2, 2)
end

return DarkMenu