local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main")

    self.state = "MAIN"

    self.text = Text("The quick brown fox jumps over the lazy dog.", 0, 240 + 32, {
        ["align"] = "center"
    })
    self.stage:addChild(self.text)
end

function Testing:update()
    if Input.pressed("h") then
        Kristal.fetch("https://api.github.com/repos/KristalTeam/Kristal/commits?per_page=1", {
            headers = {
                ["User-Agent"] = "Kristal/" .. tostring(Kristal.Version)
            },
            callback = function(resp, body, headers)
                print(body)
                --local json = JSON.decode(body)
                --print(json[1]["sha"])
            end
        })
    end
    self.stage:update()
end

function Testing:draw()
    Draw.setColor(1, 1, 1, 1)

    love.graphics.setFont(self.font)

    if self.state == "MAIN" then
        love.graphics.printf("~ テスティング ~", 0, 16, 640, "center")

        love.graphics.printf("The quick brown fox jumps over the lazy dog.", 0, 240, 640, "center")
    elseif self.state == "GAMEPAD" then
        love.graphics.printf("~ コントローラーテスト ~", 0, 16, 640, "center")
        self:drawGamepad()
    end

    Draw.setColor(COLORS.white)
    local tex = Assets.getTexture("kristal/lancer/wave_9")
    Draw.draw(tex, 320, 480, 0, 2, 2, tex:getWidth() / 2, tex:getHeight())

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
