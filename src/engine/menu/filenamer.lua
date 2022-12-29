---@class FileNamer : Object
---@overload fun(...) : FileNamer
local FileNamer, super = Class(Object)

function FileNamer:init(limit, callback, name_text, confirm_text, default_name, default_name_select)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- KEYBOARD, CONFIRM, FADEOUT, DONE, TRANSITION
    self.state = ""

    self.name = default_name or ""
    self.name_limit = limit or 12

    self.default_name = default_name or ""

    self.name_text    = name_text    or ("[style:GONER][spacing:3.2]ENTER YOUR OWN NAME.")
    self.confirm_text = confirm_text or ("[style:GONER][spacing:3.2]THIS IS YOUR NAME.")

    self.callback = callback
    self.cancel_callback = nil

    self.text = Text("", 136, 40, {wrap = false, font = "main_mono"})
    self:addChild(self.text)

    self.keyboard = nil
    self.choicer = nil
    self.name_preview = nil

    self.do_fadeout = false

    self.whiten = 0
    self.name_zoom = 0

    self.timer = Timer()
    self:addChild(self.timer)

    if default_name_select and self.default_name ~= "" then
        self:setState("CONFIRM")
    else
        self:setState("KEYBOARD")
    end
end

function FileNamer:checkTransition(old, new)
    if self.state == "KEYBOARD" and self.keyboard and not self.keyboard.done then
        self.keyboard:finish()
        self.timer:afterCond(function() return self.keyboard.done end, function()
            self.keyboard = nil
            self:setState(new)
        end)
        return true
    elseif self.state == "CONFIRM" and self.choicer and not self.choicer.done then
        self.choicer:finish()
        if new == "KEYBOARD" then
            self.name_preview:remove()
            self.name_preview = nil
            self.timer:after(1/30, function()
                self.text:setText("")
                self.choicer:remove()
                self.choicer = nil
                self.timer:after(1/30, function()
                    self:setState(new)
                end)
            end)
            return true
        end
    end
end

function FileNamer:setState(state)
    if state == self.state then return end

    if self:checkTransition(self.state, state) then
        self.state = "TRANSITION"
        return
    end

    self.state = state

    if state == "KEYBOARD" then
        self.text:setText(self.name_text)
        self.text.x = self.text.init_x
        self.keyboard = GonerKeyboard(self.name_limit, "default", function(text)
            self.name = text
            self:setState("CONFIRM")
        end, function(key, x, y, namer)
            if namer.text == "GASTE" and key == "R" then
                love.audio.stop()
                self.stage.timescale = 0
                for _,child in ipairs(self.stage.children) do
                    child.active = false
                end
                Kristal.Stage.timer:after(0.1, function()
                    love.event.quit("restart")
                end)
            end
        end)
        if self.name == self.default_name and self.default_name ~= "" then
            self.keyboard.text = self.default_name
            self.keyboard.choicer:setSelectedOption(9, 3)
            self.keyboard.choicer:resetSoulPosition()
        end
        self:addChild(self.keyboard)
    elseif state == "CONFIRM" then
        self.text:setText(self.confirm_text)
        self.text.x = self.text.init_x - 4
        self.name_preview = Text(self.name, SCREEN_WIDTH/2, 80, {wrap = false, font = "main", auto_size = true})
        self.name_preview:setOrigin(0.5, 0)
        self:addChild(self.name_preview)
        self.name_zoom = 0
        self.choicer = GonerChoice(220, 360, {
            {{"NO",0,0},{"<<"},{">>"},{"YES",160,0}}
        }, nil, function(choice, x, y)
            if choice == "YES" then
                if self.do_fadeout then
                    self:setState("FADEOUT")
                else
                    self:setState("DONE")
                end
            elseif choice == "NO" then
                self:setState("KEYBOARD")
            end
        end)
        if self.name == self.default_name and self.default_name ~= "" then
            self.choicer:setSelectedOption(4, 1)
            self.choicer:resetSoulPosition()
        else
            self.choicer:setSelectedOption(2, 1)
            self.choicer:setSoulPosition(80, 0)
        end
        self:addChild(self.choicer)
    elseif state == "FADEOUT" then
        Music.stop()
        Assets.playSound("dtrans_lw")
        self.timer:tween(80/30, self, {whiten = 1})
        self.timer:after(80/30, function()
            self:setState("DONE")
        end)
    elseif state == "DONE" then
        if self.callback then
            self.callback(self.name)
        end
    end
end

function FileNamer:update()
    if self.cancel_callback and self.state == "KEYBOARD" and Input.pressed("cancel") then
        if not self.keyboard or self.keyboard.text == "" then
            self.state = "TRANSITION"

            self.timer:after(1/30, function()
                self.cancel_callback()
            end)
        end
    end

    if self.name_preview then
        if self.state == "CONFIRM" and self.name_zoom < 100 then
            self.name_zoom = Utils.approach(self.name_zoom, 100, 2 * DTMULT)
        end

        self.name_preview:setScale(1 + self.name_zoom/100, 1 + self.name_zoom/100)
        self.name_preview.rotation = -math.rad(1 + Utils.random(4))
        self.name_preview.y = 80 + self.name_zoom
    end

    super.update(self)
end

function FileNamer:draw()
    super.draw(self)

    if self.whiten > 0 then
        love.graphics.setColor(1, 1, 1, self.whiten)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return FileNamer