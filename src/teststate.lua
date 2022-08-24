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

    love.graphics.setColor(COLORS.white)
    love.graphics.circle("line", 120 + Input.gamepad_left_x * 40, 418 + Input.gamepad_left_y * 40, 20)

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