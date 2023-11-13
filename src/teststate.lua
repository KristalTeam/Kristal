local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main", 32)

    self.state = "MAIN"

    self.scrollbar_arrows = false
    self.scrollbar_type = 1
    self.scrollbar_width = 9

    local outer = Component(FixedSizing(640, 480))
        outer:setLayout(VerticalLayout({ gap = 0, align = "center" }))
        outer:setOverflow("hidden")
        local inner = Component(FillSizing(), FitSizing())
            inner:setLayout(HorizontalLayout({ gap = 0, align = "center" }))
            local box = MainMenuBoxComponent(FitSizing())
                local menu = EasingSoulMenuComponent(FitSizing(), FixedSizing(240), {hold=true})
                    menu:setScrollbar(ScrollbarComponent({gutter = "dotted", margins = {8, 0, 0, 0}, arrows = true}))
                    menu:setLayout(VerticalLayout({ gap = 0, align = "start" }))
                    menu:setOverflow("scroll")
                    menu:setScrollType("paged")

                    menu:addChild(BooleanMenuItemComponent(self.scrollbar_arrows, function(value) self.scrollbar_arrows = value self:updateScrollbar(menu) end, {on_text="Arrows ON", off_text="Arrows OFF"}))
                    menu:addChild(ArrowListMenuItemComponent({ "Dotted", "Fill", "No Gutter" }, self.scrollbar_type, function(index) self.scrollbar_type = index self:updateScrollbar(menu) end))
                    menu:addChild(ArrowIntegerMenuItemComponent(1, 32, self.scrollbar_width, function(value) self.scrollbar_width = value self:updateScrollbar(menu) end, {wrap = false, hold = true, prefix = "Width "}))
                    menu:addChild(SeparatorComponent())
                    menu:addChild(LabelMenuItemComponent("Label: ", IntegerMenuItemComponent(1, 10, 1), FillSizing(), FitSizing()))
                    menu:addChild(SeparatorComponent())
                    menu:addChild(TextInputComponent())
                    menu:addChild(BooleanMenuItemComponent(false, function(value) end))
                    menu:addChild(ListMenuItemComponent({ "List Option 1", "List Option 2", "List Option 300" }, 1, function(index) end))
                    menu:addChild(ArrowListMenuItemComponent({ "List Option 1", "List Option 2", "List Option 300" }, 1, function(index) end))
                    menu:addChild(IntegerMenuItemComponent(1, 10, 1, function(value) end))
                    menu:addChild(IntegerMenuItemComponent(1, 10, 1, function(value) end, {wrap = false, hold = true}))
                    menu:addChild(ArrowIntegerMenuItemComponent(1, 10, 1, function(value) end))
                    menu:addChild(ArrowIntegerMenuItemComponent(1, 10, 1, function(value) end, {wrap = false, hold = true}))
                    -- recreate the deltarune volume controller
                    menu:addChild(ArrowIntegerMenuItemComponent(0, 100, 60, function(value) Kristal.setVolume(value / 100) end, {step = 2, suffix = "%", sound = "noise", wrap = false, hold = true, sound_delay = 3, sound_at_limit = true}))
                    menu:addChild(TextMenuItemComponent(Text("Option"),
                        function()
                            menu.visible = false
                            local menu2 = EasingSoulMenuComponent(FitSizing(), FitSizing(), {hold=true})
                            menu2:setLayout(VerticalLayout())
                            menu2:addChild(TextMenuItemComponent(Text("Option 1"), function() end))
                            menu2:addChild(TextMenuItemComponent(Text("Option 2"), function() end))
                            menu2:setCancelCallback(function()
                                menu2:close()
                                menu.visible = true
                            end)
                            menu2:setFocused()
                            box:addChild(menu2)
                        end, {highlight=false}
                    ))
                    menu:setSelected(2)
                    menu:setFocused()
                box:addChild(menu)
            inner:addChild(box)
        outer:addChild(inner)
    self.stage:addChild(outer)

    self:updateScrollbar(menu)
end

function Testing:updateScrollbar(menu)
    local gutter = "dotted"
    if self.scrollbar_type == 2 then
        gutter = "fill"
    elseif self.scrollbar_type == 3 then
        gutter = "none"
    end
    menu:setScrollbar(ScrollbarComponent({gutter = gutter, margins = {8, 0, 0, 0}, arrows = self.scrollbar_arrows, width = self.scrollbar_width}))

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
