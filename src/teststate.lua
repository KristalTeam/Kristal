local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main")

    self.state = "MAIN"

    local window = UIWindow(0, 0, 640, 480)
    window.padding = { 20, 20, 20, 20 }
    window.margins = { 20, 20, 20, 20 }
    window:setLayout(VerticalLayout({ horizontal = "centered" }))
    window:addChild(Text("hey1"))
    window:addChild(Text("hey2"))
    window:addChild(Text("hey3"))
    window:addChild(Text("hey4"))
    window:addChild(Text("hey5"))
    self.stage:addChild(window)
end

function Testing:update()
    self.stage:update()
end

function Testing:draw()
    Draw.setColor(1, 1, 1, 1)

    if self.state == "GAMEPAD" then
        love.graphics.setFont(self.font)
        love.graphics.printf("~ コントローラーテスト ~", 0, 16, 640, "center")
        self:drawGamepad()
    end

    self.stage:draw()
end

function Testing:drawGamepad()
    local radius = 40
    local circle_size = 10

    Draw.setColor(COLORS.ltgray)
    love.graphics.circle("line", 120, 418, radius)

    Draw.setColor(COLORS.white)
    love.graphics.circle("line", 120 + Input.gamepad_left_x * radius, 418 + Input.gamepad_left_y * radius, circle_size)

    local thing_x, thing_y = Input.getLeftThumbstick()

    Draw.setColor(COLORS.red)
    love.graphics.circle("line", 120 + thing_x * radius, 418 + thing_y * radius, circle_size)

    Draw.setColor(COLORS.white)

    Draw.setColor(Input.down("gamepad:left") and COLORS.white or COLORS.gray)
    love.graphics.print("[<]", 64, 400)
    Draw.setColor(Input.down("gamepad:down") and COLORS.white or COLORS.gray)
    love.graphics.print("[V]", 104, 426)
    Draw.setColor(Input.down("gamepad:right") and COLORS.white or COLORS.gray)
    love.graphics.print("[>]", 144, 400)
    Draw.setColor(Input.down("gamepad:up") and COLORS.white or COLORS.gray)
    love.graphics.print("[^]", 104, 374)


    Draw.setColor(Input.down("left") and COLORS.white or COLORS.gray)
    love.graphics.print("[<]", 466, 400)
    Draw.setColor(Input.down("down") and COLORS.white or COLORS.gray)
    love.graphics.print("[V]", 506, 400)
    Draw.setColor(Input.down("right") and COLORS.white or COLORS.gray)
    love.graphics.print("[>]", 546, 400)
    Draw.setColor(Input.down("up") and COLORS.white or COLORS.gray)
    love.graphics.print("[^]", 506, 374)
end

return Testing
