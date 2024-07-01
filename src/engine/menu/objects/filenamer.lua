---@class FileNamer : Object
---@overload fun(options?:table) : FileNamer
local FileNamer, super = Class(Object)

--function FileNamer:init(limit, callback, name_text, confirm_text, default_name, default_name_select)
function FileNamer:init(options)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    options = options or {}

    -- KEYBOARD, CONFIRM, FADEOUT, DONE, TRANSITION
    self.state = ""

    self.name = options.name or ""
    self.name_limit = options.limit or 12

    self.default_name = options.name or ""

    local mod = options.mod or {}

    self.name_text    = options.name_text    or mod["nameText"]    or "ENTER YOUR OWN NAME."
    self.confirm_text = options.confirm_text or mod["confirmText"] or "THIS IS YOUR NAME."

    if options.goner_style ~= false then
        self.name_text    = "[style:GONER][spacing:3.2]" .. self.name_text
        self.confirm_text = "[style:GONER][spacing:3.2]" .. self.confirm_text
        self.goner_style = true
    else
        self.goner_style = false
    end

    self.crash_names   = options.crash_names   or mod["namesCrash"]    or {"GASTER"}
    self.deny_names    = options.deny_names    or mod["namesDeny"]     or {}
    self.name_messages = options.name_messages or mod["namesMessages"] or {}
    
    self.keyboard_mode = options.keyboard_mode or mod["keyboardMode"] or "default"

    self.callback = options.on_confirm
    self.cancel_callback = options.on_cancel

    self.text = Text("", 136, 40, {wrap = false, font = "main_mono"})
    self:addChild(self.text)

    self.keyboard = nil
    self.choicer = nil
    self.name_preview = nil

    self.do_fadeout = options.white_fade

    self.whiten = 0
    self.name_zoom = 0

    self.timer = Timer()
    self:addChild(self.timer)

    if options.start_confirm and self.default_name ~= "" then
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
        self.keyboard = GonerKeyboard(self.name_limit, self.keyboard_mode, function(text)
            self.name = text
            self:setState("CONFIRM")
        end, function(key, x, y, namer)
            for k,v in pairs(self.crash_names) do
                if namer.text .. key == v then
                    love.audio.stop()
                    self.stage.timescale = 0
                    for _,child in ipairs(self.stage.children) do
                        child.active = false
                    end
                    love.event.quit("restart")
                end
            end
        end)
        if self.name == self.default_name and self.default_name ~= "" then
            self.keyboard.text = self.default_name
            self.keyboard.choicer:setSelectedOption(9, 3)
            self.keyboard.choicer:resetSoulPosition()
        end
        self:addChild(self.keyboard)
    elseif state == "CONFIRM" then
        local confirm_text = self.confirm_text
        for k,v in pairs(self.name_messages) do
            if k == self.name then
                confirm_text = v
            end
        end
        self.text:setText(confirm_text)
        self.text.x = self.text.init_x - 4
        self.name_preview = Text(self.name, SCREEN_WIDTH/2, 80, {wrap = false, font = "main", auto_size = true})
        self.name_preview:setOrigin(0.5, 0)
        self:addChild(self.name_preview)
        self.name_zoom = 0
        local allow = true
        for k,v in pairs(self.deny_names) do
            if v == self.name then
                allow = false
            end
        end
        if allow then
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
        else
            self.choicer = GonerChoice(220, 360, {
                {{"NO",0,0}}
            }, nil, function(choice, x, y)
                self:setState("KEYBOARD")
            end)
        end
        if self.name == self.default_name and self.default_name ~= "" then
            self.choicer:setSelectedOption(4, 1)
            self.choicer:resetSoulPosition()
        elseif allow then
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
        Draw.setColor(1, 1, 1, self.whiten)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        Draw.setColor(1, 1, 1, 1)
    end
end

return FileNamer
