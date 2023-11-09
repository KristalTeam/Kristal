local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main")

    self.state = "MAIN"

    local outer = Component(0, 0, FixedSizing(640, 480))
        outer:setLayout(VerticalLayout({ gap = 0, align = "center" }))
        outer:setOverflow("hidden")
        local inner = Component(0, 0, FillSizing(), FitSizing())
            inner:setLayout(HorizontalLayout({ gap = 0, align = "center" }))
            local box = BoxComponent(0, 0, FitSizing())
                local menu = EasingSoulMenuComponent(0, 0, FitSizing())
                    menu:setPadding(0, 0, 20, 0)
                    menu:setLayout(VerticalLayout({ gap = 0, align = "start" }))
                    menu:addChild(SoulMenuItemComponent(Text("Option 1"), function() end))
                    menu:addChild(SoulMenuItemComponent(Text("Option 2"), function() end))
                    menu:addChild(SoulMenuItemComponent(Text("Option 3"), function() end))
                    menu:addChild(SoulMenuItemComponent(Text("Option 4"), function() end))
                    menu:addChild(SoulMenuItemComponent(Text("Option 5"), function() end))
                box:addChild(menu)
            inner:addChild(box)
        outer:addChild(inner)
    self.stage:addChild(outer)
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
