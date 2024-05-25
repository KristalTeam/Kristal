local RecruitMenu, super = Class(Object)

function RecruitMenu:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self:setParallax(0, 0)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.heart = Sprite("player/heart_menu")
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setColor(Game:getSoulColor())
    self.heart.layer = 100
    self:addChild(self.heart)
    
    self.arrow_left = Assets.getTexture("ui/flat_arrow_left")
    self.arrow_right = Assets.getTexture("ui/flat_arrow_right")
    
    self.enemy_box = Sprite("ui/menu/recruit_gradient", 370, 75)
    self:addChild(self.enemy_box)
    
    -- self.enemy = Sprite(Game.enemies_data["virovirokun"].actor.path .. "/idle", 20, 20)
    -- self.enemy:setScale(2)
    -- self.enemy:setOrigin(0.5, 0.5)
    -- self.enemy_box:addChild(self.enemy)
end

function RecruitMenu:update()
    if Input.pressed("up") then
        self.selected_y[self.list] = self.selected_y[self.list] - 1
        if self.selected_y[self.list] < 1 then
            self.selected_y[self.list] = 6
        end
    end
    if Input.pressed("down") then
        self.selected_y[self.list] = self.selected_y[self.list] + 1
        if self.selected_y[self.list] > 6 then
            self.selected_y[self.list] = 1
        end
    end
    if Input.pressed("cancel") then
        self:remove()
        Game.world:closeMenu()
    end
end

function RecruitMenu:draw()
    love.graphics.setLineWidth(4)
    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("line", 32, 12, 587, 427)
    Draw.setColor(PALETTE["world_fill"])
    love.graphics.rectangle("fill", 34, 14, 583, 423)
    
    love.graphics.setLineWidth(1)
    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("line", self.enemy_box.x, self.enemy_box.y, self.enemy_box.width + 1, self.enemy_box.height + 1)
    
    love.graphics.setFont(self.font)
    
    Draw.setColor(COLORS["white"])
    love.graphics.print("Recruits", 80, 30)
    Draw.setColor({0,1,0})
    love.graphics.print("PROGRESS", 270, 30, 0, 0.5, 1)
    
    local offset = 0
    for id,enemy in pairs(Game.enemies_data) do
        if enemy:isRecruitable() and (enemy:getRecruitStatus() == true or enemy:getRecruitStatus() > 0) then
            Draw.setColor(COLORS["white"])
            love.graphics.print(enemy.recruit_data["name"], 80, 100 + offset)
            if enemy:getRecruitStatus() == true then
                Draw.setColor({0,1,0})
                love.graphics.print("Recruited!", 275, 100 + offset, 0, 0.5, 1)
            else
                Draw.setColor(PALETTE["world_light_gray"])
                love.graphics.print(enemy:getRecruitStatus() .. " / " .. enemy.recruit_amount, 280, 100 + offset)
            end
            offset = offset + 35
        end
    end

    super.draw(self)
end

return RecruitMenu