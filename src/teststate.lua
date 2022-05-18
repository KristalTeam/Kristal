local Testing = {}

function Testing:enter()
    self.stage = Stage()

    self.draw_text = true
end

function Testing:update()
    self.stage:update()
end

function Testing:draw()
    if self.draw_text then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(Assets.getFont("main"))
        love.graphics.printf("~ TESTING STATE ~", 0, 16, 640, "center")
    end
    self.stage:draw()
end

return Testing