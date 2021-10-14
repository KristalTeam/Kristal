example_state = {}

function example_state:enter(previous)
    self.previous_state = previous

    print("Loaded example mod!")

    self.stage = Stage()

    self.world = World("alley")
    self.stage:addChild(self.world)

    self.chara = Character("kris", self.world.markers["spawn"].center_x, self.world.markers["spawn"].center_y)
    self.world:addChild(self.chara)

    self.world.camera:lookAt(self.chara:getPosition())
    self.previous_state.final_y = self.world.markers["spawn"].center_y - self.world.camera.y
    self.chara.x = self.world.camera.x + self.previous_state.kris_x
    --[[self.banana = Sprite("banana", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.banana:setOrigin(0.5, 0.5)
    self.banana:play()
    STAGE:addChild(self.banana)

    STAGE:addChild(DialogueText("* [speed:0.05]Potassium", SCREEN_WIDTH/2 - 104, SCREEN_HEIGHT/2 - 120))]]
end

function example_state:update(dt)
    local walk_x = 0
    local walk_y = 0

    if love.keyboard.isDown("right") then walk_x = walk_x + 1 end
    if love.keyboard.isDown("left") then walk_x = walk_x - 1 end
    if love.keyboard.isDown("down") then walk_y = walk_y + 1 end
    if love.keyboard.isDown("up") then walk_y = walk_y - 1 end

    self.chara:walk(walk_x, walk_y, love.keyboard.isDown("lshift"))
    self.world.camera:lookAt(self.chara:getPosition())

    self.stage:update(dt)

    if self.previous_state.animation_active then
        self.previous_state:update(dt)
    end
end

function example_state:draw()
    self.stage:draw()

    if self.previous_state.animation_active then
        self.previous_state:draw(true)
    end
end