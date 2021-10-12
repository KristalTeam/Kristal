example_state = {}

function example_state:enter()
    print("Loaded example mod!")

    STAGE = Object()

    self.banana = Sprite("banana", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.banana:setOrigin(0.5, 0.5)
    self.banana:play()
    STAGE:add(self.banana)

    STAGE:add(DialogueText("* [speed:0.05]Potassium", SCREEN_WIDTH/2 - 104, SCREEN_HEIGHT/2 - 120))
end

function example_state:update(dt)
    self.banana:setScale(self.banana:getScale() + (dt * (2/3)))

    STAGE:update(dt)
end

function example_state:draw()
    STAGE:draw()
end