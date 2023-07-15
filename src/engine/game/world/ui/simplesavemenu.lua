---@class SimpleSaveMenu : Object
---@overload fun(...) : SimpleSaveMenu
local SimpleSaveMenu, super = Class(Object)

function SimpleSaveMenu:init(save_id, marker)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.parallax_x = 0
    self.parallax_y = 0

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.heart_sprite = Assets.getTexture("player/heart")

    self.box = UIBox(140, 130, 359, 109)
    self.box.layer = -1
    self:addChild(self.box)

    self.marker = marker

    -- MAIN, SAVED
    self.state = "MAIN"

    self.selected_x = 1

    self.save_id = save_id or Game.save_id
    self.saved_file = Kristal.getSaveFile(save_id)
end

function SimpleSaveMenu:update()
    if self.state == "MAIN" then
        if Input.pressed("cancel") then
            self:remove()
            Game.world:closeMenu()
        end
        if Input.pressed("left") or Input.pressed("right") then
            self.selected_x = self.selected_x == 1 and 2 or 1
        end
        if Input.pressed("confirm") then
            if self.selected_x == 1 then
                self.state = "SAVED"

                Kristal.saveGame(self.save_id, Game:save(self.marker))
                self.saved_file = Kristal.getSaveFile(self.save_id)

                Assets.playSound("save")
            elseif self.selected_x == 2 then
                self:remove()
                Game.world:closeMenu()
            end
        end
    elseif self.state == "SAVED" then
        if Input.pressed("confirm") or Input.pressed("cancel") then
            self:remove()
            Game.world:closeMenu()
        end
    end

    super.update(self)
end

function SimpleSaveMenu:draw()
    love.graphics.setFont(self.font)

    if self.state == "SAVED" then
        Draw.setColor(PALETTE["world_text_selected"])
    else
        Draw.setColor(PALETTE["world_text"])
    end

    local data = self.saved_file or {}
    local name      = data.name      or "[EMPTY]"
    local level     = data.level     or 0
    local playtime  = data.playtime  or 0
    local room_name = data.room_name or ""

    love.graphics.print(name,         self.box.x,       self.box.y - 10)
    love.graphics.print("LV "..level, self.box.x + 210, self.box.y - 10)

    local minutes = math.floor(playtime / 60)
    local seconds = math.floor(playtime % 60)
    local time_text = string.format("%d:%02d", minutes, seconds)
    love.graphics.print(time_text, self.box.x + 280, self.box.y - 10)

    love.graphics.print(room_name, self.box.x, self.box.y + 30)

    if self.state == "MAIN" then
        love.graphics.print("Save",   self.box.x + 30,  self.box.y + 90)
        love.graphics.print("Return", self.box.x + 210, self.box.y + 90)

        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, self.box.x + 2 + (self.selected_x - 1) * 180, self.box.y + 96)
    elseif self.state == "SAVED" then
        love.graphics.print("File saved.", self.box.x + 30, self.box.y + 90)
    end

    Draw.setColor(1, 1, 1)

    super.draw(self)
end

return SimpleSaveMenu