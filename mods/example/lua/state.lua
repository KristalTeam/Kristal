example_state = {}

function example_state:enter()
    print("Loaded example mod!")

    STAGE = Object()

    self.banana = Sprite("banana", WIDTH/2, HEIGHT/2)
    self.banana.origin = Vector(0.5, 0.5)
    STAGE:add(self.banana)

    STAGE:add(DialogueText("* [speed:0.05]Potassium", WIDTH/2 - 104, HEIGHT/2 - 120))
end

function example_state:update(dt)
    self.banana.scale = self.banana.scale + Vector(dt * (2/3), dt * (2/3))

    STAGE:update(dt)
end

function example_state:draw()
    STAGE:draw()
end