example_state = {}

function example_state:enter()
    print("Loaded example mod!")

    STAGE = Object()

    local sprite = Sprite("banana", WIDTH/2, HEIGHT/2)
    sprite.origin = Vector(0.5, 0.5)
    sprite.scale = Vector(4, 4)
    STAGE:add(sprite)

    STAGE:add(DialogueText("* Potassium", WIDTH/2 - 104, HEIGHT/2 - 120))
end

function example_state:update(dt)
    STAGE:update(dt)
end

function example_state:draw()
    STAGE:draw()
end