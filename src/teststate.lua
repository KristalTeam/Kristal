local Testing = {}

function Testing:enter()
    self.stage = Stage()

    self.frame = 0
end

function Testing:update()
    self.frame = self.frame + 1

    if Input.pressed("confirm") then
        self.stage:addChild(DarkTransition(240, {has_head_object = true}))
    end

    self.stage:update()
end

function Testing:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Assets.getFont("main"))
    love.graphics.printf("~ TESTING STATE ~", 0, 48, 640, "center")
    self.stage:draw()
end

return Testing