local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main", 32)
end

function Testing:update()
    self.stage:update()
end

function Testing:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf("~ コントローラーテスト ~", 0, 16, 640, "center")

    local radius = 40
    local circle_size = 10

    love.graphics.setColor(COLORS.ltgray)
    love.graphics.circle("line", 120, 418, radius)

    love.graphics.setColor(COLORS.white)
    love.graphics.circle("line", 120 + Input.gamepad_left_x * radius, 418 + Input.gamepad_left_y * radius, circle_size)

    local thing_x, thing_y = Input.getLeftThumbstick()

    love.graphics.setColor(COLORS.red)
    love.graphics.circle("line", 120 + thing_x * radius, 418 + thing_y * radius, circle_size)

    love.graphics.setColor(COLORS.white)

    love.graphics.setColor(Input.down("gamepad:left" ) and COLORS.white or COLORS.gray) love.graphics.print("[<]", 64,  400)
    love.graphics.setColor(Input.down("gamepad:down" ) and COLORS.white or COLORS.gray) love.graphics.print("[V]", 104, 426)
    love.graphics.setColor(Input.down("gamepad:right") and COLORS.white or COLORS.gray) love.graphics.print("[>]", 144, 400)
    love.graphics.setColor(Input.down("gamepad:up"   ) and COLORS.white or COLORS.gray) love.graphics.print("[^]", 104, 374)


    love.graphics.setColor(Input.down("left" ) and COLORS.white or COLORS.gray) love.graphics.print("[<]", 466, 400)
    love.graphics.setColor(Input.down("down" ) and COLORS.white or COLORS.gray) love.graphics.print("[V]", 506, 400)
    love.graphics.setColor(Input.down("right") and COLORS.white or COLORS.gray) love.graphics.print("[>]", 546, 400)
    love.graphics.setColor(Input.down("up"   ) and COLORS.white or COLORS.gray) love.graphics.print("[^]", 506, 374)

    self.stage:draw()
end

return Testing