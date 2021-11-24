local DarkConfigMenu, super = Class(Object)

function DarkConfigMenu:init()
    super:init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow")

    self.tp_sprite = Assets.getTexture("ui/menu/caption_tp")

    self.bg = DarkBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self:addChild(self.bg)

    -- MAIN, VOLUME, CONTROLS
    self.state = "MAIN"

    self.currently_selected = 0
    self.noise_timer = 0

    self.no1 = false
end

function DarkConfigMenu:update(dt)
    if self.state == "MAIN" then
        if Input.pressed("confirm") then
            self.ui_select:stop()
            self.ui_select:play()

            if self.currently_selected == 1 then
                self.state = "VOLUME"
                self.noise_timer = 0
            elseif self.currently_selected == 2 then
                --self.state = "CONTROLS"
                self.no1 = true
            elseif self.currently_selected == 3 then
                Kristal.Config["simplifyVFX"] = not Kristal.Config["simplifyVFX"]
            elseif self.currently_selected == 4 then
                Kristal.Config["fullscreen"] = not Kristal.Config["fullscreen"]
                love.window.setFullscreen(Kristal.Config["fullscreen"])
            elseif self.currently_selected == 5 then
                Kristal.Config["autoRun"] = not Kristal.Config["autoRun"]
            elseif self.currently_selected == 6 then
                Game.state = "EXIT"
            elseif self.currently_selected == 7 then
                Game.world.menu:closeBox()
            end

            return
        end

        if Input.pressed("cancel") then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            Game.world.menu:closeBox()
            return
        end

        if Input.pressed("up") then
            self.currently_selected = self.currently_selected - 1
            self.ui_move:stop()
            self.ui_move:play()
        end
        if Input.pressed("down") then
            self.currently_selected = self.currently_selected + 1
            self.ui_move:stop()
            self.ui_move:play()
        end

        self.currently_selected = Utils.clamp(self.currently_selected, 1, 7)
    elseif self.state == "VOLUME" then
        if Input.pressed("cancel") or Input.pressed("confirm") then
            Game:setVolume(Utils.round(Game:getVolume() * 100) / 100)
            self.ui_select:stop()
            self.ui_select:play()
            self.state = "MAIN"
            return
        end

        self.noise_timer = self.noise_timer + DTMULT
        if Input.down("left") then
            Game:setVolume(Game:getVolume() - ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("snd_noise")
            end
        end
        if Input.down("right") then
            Game:setVolume(Game:getVolume() + ((2 * DTMULT) / 100))
            if self.noise_timer >= 3 then
                self.noise_timer = self.noise_timer - 3
                Assets.stopAndPlaySound("snd_noise")
            end
        end
        if (not Input.down("right")) and (not Input.down("left")) then
            self.noise_timer = 3
        end
    end
    super:update(self, dt)
end

function DarkConfigMenu:draw()
    if Game.state == "EXIT" then
        super:draw(self)
        return
    end
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("CONFIG", 188, -12)

    if self.state == "VOLUME" then
        love.graphics.setColor(1, 1, 0, 1)
    end
    love.graphics.print("Master Volume",   88, 38 + (0 * 32))
    love.graphics.setColor(1, 1, 1, 1)
    if self.no1 then
        love.graphics.print("No not yet", 88, 38 + (1 * 32))
    else
        love.graphics.print("Controls",        88, 38 + (1 * 32))
    end
    love.graphics.print("Simplify VFX",    88, 38 + (2 * 32))
    love.graphics.print("Fullscreen",      88, 38 + (3 * 32))
    love.graphics.print("Auto-Run",        88, 38 + (4 * 32))
    love.graphics.print("Return to Title", 88, 38 + (5 * 32))
    love.graphics.print("Back",            88, 38 + (6 * 32))

    if self.state == "VOLUME" then
        love.graphics.setColor(1, 1, 0, 1)
    end
    love.graphics.print(Utils.round(Game:getVolume() * 100) .. "%",      348, 38 + (0 * 32))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(Kristal.Config["simplifyVFX"] and "ON" or "OFF", 348, 38 + (2 * 32))
    love.graphics.print(Kristal.Config["fullscreen"]  and "ON" or "OFF", 348, 38 + (3 * 32))
    love.graphics.print(Kristal.Config["autoRun"]     and "ON" or "OFF", 348, 38 + (4 * 32))

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.draw(self.heart_sprite,  88 - 32 + 7, 48 + ((self.currently_selected - 1) * 32))

    love.graphics.setColor(1, 1, 1, 1)

    super:draw(self)
end

return DarkConfigMenu