local TestState = {}

function TestState:enter()
    self.anim = Animation("ui/quit")
end

function TestState:update(dt)
    self.anim:update(dt)

    if love.keyboard.isDown("f") then
        self.anim:play("test")
    end
end

function TestState:draw()
    love.graphics.scale(2)
    self.anim:draw()
end

return TestState