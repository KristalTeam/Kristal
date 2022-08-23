local Testing = {}

function Testing:enter()
    self.stage = Stage()

    self.draw_text = true

    self.test_string = "* 本当にいいんですか？"
    self.font = Assets.getFont("ja_main", 32)

    self.draw_count = 0
end

function Testing:update()
    if Input.pressed("f8") then
        self.test_string = "* 本当にいいんですか？"
        --self.font = love.graphics.newFont("assets/fonts/main.ttf", 32)
        --self.font:setFallbacks(Assets.getFont("ja_main", 28))
    end

    self.stage:update()
end

function Testing:unicodeTest(test_string, str_start, str_end)

    self.draw_count = self.draw_count + 1

    local test_1 = string.sub(test_string, str_start, str_end)
    local test_2 = Utils .sub(test_string, str_start, str_end)

    local match = test_1 == test_2

    love.graphics.setColor(match and {0, 1, 0} or {1, 0, 0})
    love.graphics.print(match and "[O]" or "[X]", 0, 64 + (self.draw_count * 32))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(test_1 .. " -- " .. test_2, 48, 64 + (self.draw_count * 32))
    return match, test_1, test_2
end

function Testing:draw()
    if self.draw_text then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        love.graphics.printf("~ TESTING STATE ~", 0, 16, 640, "center")
        --love.graphics.print(self.test_string, 0, 64)

        self.draw_count = 0
        self:unicodeTest(self.test_string, 0, 1)
        self:unicodeTest(self.test_string, 0, 0)
        self:unicodeTest(self.test_string, 0, -1)
        self:unicodeTest(self.test_string, 0, nil)
        self:unicodeTest(self.test_string, 1, 0)
        self:unicodeTest(self.test_string, 2, 0)
        --self:unicodeTest(self.test_string, 0, 10)


    end
    self.stage:draw()
end

return Testing