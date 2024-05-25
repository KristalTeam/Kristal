local RecruitMenu, super = Class(Object)

function RecruitMenu:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self:setParallax(0, 0)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")
    self.description_font = Assets.getFont("plain")

    self.heart = Sprite("player/heart", 58, 114)
    self.heart:setOrigin(0.5, 0.5)
    self.heart:setColor(Game:getSoulColor())
    self.heart.layer = 100
    self:addChild(self.heart)
    
    self.arrow_left = Assets.getTexture("ui/flat_arrow_left")
    self.arrow_right = Assets.getTexture("ui/flat_arrow_right")
    
    self.enemy_box = Sprite("ui/menu/recruit_gradient", 370, 75)
    self:addChild(self.enemy_box)
    
    self.state = "SELECT"
    
    self.selected = 1
    
    -- I had no idea how to make the animation play, or get the idle animation of the enemy normally, this isn't suppose to be scripted like that, I was testing to see if I can do it.
    
    --[[
        if Game.enemies_data["virovirokun"] then
            self.enemy = Sprite(Game.enemies_data["virovirokun"].actor.path .. "/idle", 100, 80)
            self.enemy:setScale(2)
            self.enemy:setOrigin(0.5, 0.5)
            self.enemy_box:addChild(self.enemy)
        end
    ]]
end

function RecruitMenu:update()
    if Input.pressed("up") and self.state == "SELECT" or Input.pressed("left") and self.state == "INFO" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #Game:getRecruits(true)
        end
    end
    if Input.pressed("down") and self.state == "SELECT" or Input.pressed("right") and self.state == "INFO" then
        self.selected = self.selected + 1
        if self.selected > #Game:getRecruits(true) then
            self.selected = 1
        end
    end
    if Input.pressed("confirm") then
        if self.state == "SELECT" then
            self.state = "INFO"
            self.enemy_box:setPosition(80, 70)
        end
    end
    if Input.pressed("cancel") then
        if self.state == "SELECT" then
            self:remove()
            Game.world:closeMenu()
        else
            self.state = "SELECT"
            self.enemy_box:setPosition(370, 75)
        end
    end
    
    -- Update the heart target position
    if self.state == "SELECT" then
        self.heart_target_x = 58
        self.heart_target_y = 114 + (self.selected - 1) * 35
    else
        self.heart_target_x = 58
        self.heart_target_y = 416
    end
    
    -- Move the heart closer to the target
    if (math.abs((self.heart_target_x - self.heart.x)) <= 2) then
        self.heart.x = self.heart_target_x
    end
    if (math.abs((self.heart_target_y - self.heart.y)) <= 2) then
        self.heart.y = self.heart_target_y
    end
    self.heart.x = self.heart.x + ((self.heart_target_x - self.heart.x) / 2) * DTMULT
    self.heart.y = self.heart.y + ((self.heart_target_y - self.heart.y) / 2) * DTMULT
end

function RecruitMenu:draw()
    love.graphics.setFont(self.font)
    
    if self.state == "SELECT" then
        love.graphics.setLineWidth(4)
        Draw.setColor(PALETTE["world_border"])
        love.graphics.rectangle("line", 32, 12, 587, 427)
        Draw.setColor(PALETTE["world_fill"])
        love.graphics.rectangle("fill", 34, 14, 583, 423)
    
        Draw.setColor(COLORS["white"])
        love.graphics.print("Recruits", 80, 30)
        Draw.setColor({0,1,0})
        love.graphics.print("PROGRESS", 270, 30, 0, 0.5, 1)
        
        local offset = 0
        for i,enemy in pairs(Game:getRecruits(true)) do -- There's need to be multiple pages, I didn't have enough enemies to test that
            Draw.setColor(COLORS["white"])
            if i == self.selected then
                self.enemy_box:setColor(enemy.recruit_data["gradient_color"])
                love.graphics.printf(enemy.recruit_data["name"], 273, 240, 400, "center")
                love.graphics.print("CHAPTER " .. enemy.recruit_data["chapter"], 368, 280)
                love.graphics.printf("LV " .. enemy.recruit_data["level"], 173, 280, 400, "right")
                love.graphics.print(Input.getText("confirm") .. ": More Info", 380, 320) -- Missing controller button display
                love.graphics.print(Input.getText("cancel") .. ": Quit", 380, 352) -- Missing controller button display
                Draw.setColor(COLORS["yellow"])
            end
            love.graphics.print(enemy.recruit_data["name"], 80, 100 + offset)
            if Game:hasRecruit(enemy.id) then
                Draw.setColor({0,1,0})
                love.graphics.print("Recruited!", 275, 100 + offset, 0, 0.5, 1)
            else
                Draw.setColor(PALETTE["world_light_gray"])
                love.graphics.print(enemy:getRecruitStatus() .. " / " .. enemy.recruit_amount, 280, 100 + offset)
            end
            offset = offset + 35
        end
    elseif self.state == "INFO" then
        love.graphics.setLineWidth(4)
        Draw.setColor(PALETTE["world_border"])
        love.graphics.rectangle("line", 32, 12, 577, 437)
        Draw.setColor(PALETTE["world_fill"])
        love.graphics.rectangle("fill", 34, 14, 573, 433)
        
        Draw.setColor(COLORS["white"])
        for i,enemy in pairs(Game:getRecruits(true)) do
            love.graphics.print(self.selected .. "/" .. #Game:getRecruits(true), 569, 30, 0, 0.5, 1) -- needs to be written from right to left, no idea how to do it while maintaining the 1/2 scale
            if i == self.selected then
                self.enemy_box:setColor(enemy.recruit_data["gradient_color"])
                love.graphics.print("CHAPTER " .. enemy.recruit_data["chapter"], 300, 30, 0, 0.5, 1)
                love.graphics.print(enemy.recruit_data["name"], 300, 70)
                love.graphics.setFont(self.description_font)
                love.graphics.print(Game:hasRecruit(enemy.id) and enemy.recruit_data["description"] or "Not yet fully recruited", 301, 120) -- New line spacing is inaccurate
                love.graphics.setFont(self.font)
                love.graphics.print("LIKE", 80, 240)
                love.graphics.print(Game:hasRecruit(enemy.id) and enemy.recruit_data["like"] or "?", 180, 240)
                love.graphics.print("DISLIKE", 80, 280, 0, 0.81, 1)
                love.graphics.print(Game:hasRecruit(enemy.id) and enemy.recruit_data["dislike"] or "?", 180, 280)
                love.graphics.print("?????", 80, 320, 0, 1.15, 1)
                love.graphics.print("?????????", 180, 320)
                love.graphics.print("?????", 80, 360, 0, 1.15, 1)
                love.graphics.print("?????????", 180, 360)
                love.graphics.print("Press " .. Input.getText("cancel") .. " to Return", 80, 400) -- Missing controller button display
                
                -- This part is unfinished, same issue as above
                love.graphics.print(
                "LEVEL " .. enemy.recruit_data["level"] .. "\n" .. 
                "ATTACK " .. enemy.recruit_data["attack"] .. "\n" .. 
                "DEFENSE " .. enemy.recruit_data["defense"] .. "\n" .. 
                "ELEMENT " .. enemy.recruit_data["element"], 500, 240, 0, 0.5, 1)
            end
            
            Draw.setColor(1, 1, 1, 1)
            local offset = Utils.round(math.sin(Kristal.getTime() * 5)) * 2
            Draw.draw(self.arrow_left, 22 - offset, 218, 0, 2, 2)
            Draw.draw(self.arrow_right, 602 + offset, 218, 0, 2, 2)
        end
    else
        error("Unknown Recruit Menu State.")
    end
    
    love.graphics.setLineWidth(1)
    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("line", self.enemy_box.x, self.enemy_box.y, self.enemy_box.width + 1, self.enemy_box.height + 1)

    super.draw(self)
end

return RecruitMenu