example_state = {}

function example_state:enter()
    print("Loaded example mod!")

    self.stage = Stage()

    self.world = World("alley")
    self.stage:addChild(self.world)

    --[[self.banana = Sprite("banana", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.banana:setOrigin(0.5, 0.5)
    self.banana:play()
    STAGE:addChild(self.banana)

    STAGE:addChild(DialogueText("* [speed:0.05]Potassium", SCREEN_WIDTH/2 - 104, SCREEN_HEIGHT/2 - 120))]]
end

function example_state:update(dt)
    self.stage:update(dt)
end

function example_state:draw()
    self.stage:draw()
end