--- Displays a modal color picker for editor fields.
---@class EditorColorPicker : EditorControl
---@field alpha boolean
---@field alpha_mesh love.Mesh
---@field alpha_rect table
---@field apply_button EditorButton
---@field cancel_button EditorButton
---@field captured_control EditorControl?
---@field drag_mode string?
---@field editor Editor
---@field focused_control EditorControl?
---@field hex_input EditorTextInput
---@field hue number
---@field hue_mesh love.Mesh
---@field hue_rect table
---@field on_apply function?
---@field panel_height number
---@field panel_width number
---@field panel_x number
---@field panel_y number
---@field preview_rect table
---@field saturation number
---@field saturation_mesh love.Mesh
---@field sv_rect table
---@field value number
---@field value_mesh love.Mesh
---@overload fun(editor: Editor, value?: string|table, on_apply?: function): EditorColorPicker
local EditorColorPicker, super = Class(EditorControl)

local function newGradientMesh(vertices, usage)
    return love.graphics.newMesh(vertices, "strip", usage or "dynamic")
end

local function drawGradientMesh(mesh, rect)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh, rect.x, rect.y, 0, rect.width, rect.height)
end

local function quantizeChannel(value)
    local byte = math.floor(MathUtils.clamp(value, 0, 1) * 255 + 0.000001)
    return byte / 255
end

local function newHueMesh()
    local vertices = {}
    for index = 0, 6 do
        local position = index / 6
        local red, green, blue = ColorUtils.HSVToRGB(position, 1, 1)
        table.insert(vertices, { position, 0, position, 0, red, green, blue, 1 })
        table.insert(vertices, { position, 1, position, 1, red, green, blue, 1 })
    end
    return newGradientMesh(vertices, "static")
end

function EditorColorPicker:init(editor, value, on_apply)
    local width, height = editor:getUIDimensions()
    super.init(self, 0, 0, width, height)
    self.editor = editor
    self.on_apply = on_apply
    self.focused_control = nil
    self.captured_control = nil
    self.drag_mode = nil
    self.hex_input = self:addChild(EditorTextInput({
        editor = editor,
        placeholder = "#RRGGBB or #RRGGBBAA",
        on_submit = function(hex) return self:setHex(hex) end
    }))
    self.apply_button = self:addChild(EditorButton("Apply", function() self:apply() end))
    self.cancel_button = self:addChild(EditorButton("Cancel", function() self:cancel() end))
    self.saturation_mesh = newGradientMesh({
        { 0, 0, 0, 0, 1, 1, 1, 1 }, { 0, 1, 0, 1, 1, 1, 1, 1 },
        { 1, 0, 1, 0, 1, 1, 1, 0 }, { 1, 1, 1, 1, 1, 1, 1, 0 }
    }, "static")
    self.value_mesh = newGradientMesh({
        { 0, 0, 0, 0, 0, 0, 0, 0 }, { 0, 1, 0, 1, 0, 0, 0, 1 },
        { 1, 0, 1, 0, 0, 0, 0, 0 }, { 1, 1, 1, 1, 0, 0, 0, 1 }
    }, "static")
    self.hue_mesh = newHueMesh()
    self.alpha_mesh = newGradientMesh({
        { 0, 0, 0, 0, 1, 1, 1, 0 }, { 0, 1, 0, 1, 1, 1, 1, 0 },
        { 1, 0, 1, 0, 1, 1, 1, 1 }, { 1, 1, 1, 1, 1, 1, 1, 1 }
    })
    local color = type(value) == "table" and value or ColorUtils.tryHexToRGB(tostring(value or ""))
    color = color or { 1, 1, 1, 1 }
    self.hue, self.saturation, self.value = ColorUtils.RGBToHSV(color[1], color[2], color[3])
    self.alpha = color[4] == nil and 1 or color[4]
    self:updateHex()
end

function EditorColorPicker:getColor()
    local red, green, blue = ColorUtils.HSVToRGB(self.hue, self.saturation, self.value)
    return {
        quantizeChannel(red), quantizeChannel(green), quantizeChannel(blue),
        quantizeChannel(self.alpha)
    }
end

function EditorColorPicker:updateHex()
    local color = self:getColor()
    local red, green, blue = color[1], color[2], color[3]
    self.alpha_mesh:setVertex(1, 0, 0, 0, 0, red, green, blue, 0)
    self.alpha_mesh:setVertex(2, 0, 1, 0, 1, red, green, blue, 0)
    self.alpha_mesh:setVertex(3, 1, 0, 1, 0, red, green, blue, 1)
    self.alpha_mesh:setVertex(4, 1, 1, 1, 1, red, green, blue, 1)
    self.hex_input:setValue(ColorUtils.RGBAToHex(color), true)
end

function EditorColorPicker:setHex(value)
    value = tostring(value or "")
    local hex = value:gsub("^#", "")
    if (#hex ~= 6 and #hex ~= 8) or not hex:match("^%x+$") then return false end
    local color = ColorUtils.tryHexToRGB(value)
    if not color then return false end
    self.hue, self.saturation, self.value = ColorUtils.RGBToHSV(color[1], color[2], color[3])
    self.alpha = color[4] == nil and 1 or color[4]
    self:updateHex()
    return true
end

function EditorColorPicker:setFocus(control)
    if self.focused_control == control then return end
    if self.focused_control then self.focused_control:onBlur() end
    self.focused_control = control
    if control then control:onFocus() end
end

function EditorColorPicker:update(dt)
    self:setBounds(0, 0, self.editor:getUIDimensions())
    self.panel_width, self.panel_height = 430, 372
    self.panel_x = math.floor((self.width - self.panel_width) / 2)
    self.panel_y = math.floor((self.height - self.panel_height) / 2)
    self.sv_rect = { x = self.panel_x + 18, y = self.panel_y + 54, width = 270, height = 190 }
    self.hue_rect = { x = self.panel_x + 18, y = self.panel_y + 260, width = 270, height = 20 }
    self.alpha_rect = { x = self.panel_x + 18, y = self.panel_y + 298, width = 270, height = 20 }
    self.preview_rect = { x = self.panel_x + 308, y = self.panel_y + 54, width = 104, height = 72 }
    self.hex_input:setBounds(self.panel_x + 18, self.panel_y + 332, 270, 28)
    self.apply_button:setBounds(self.panel_x + 308, self.panel_y + 296, 104, 28)
    self.cancel_button:setBounds(self.panel_x + 308, self.panel_y + 332, 104, 28)
    super.update(self, dt)
end

function EditorColorPicker:updateDrag(x, y)
    if self.drag_mode == "sv" then
        self.saturation = MathUtils.clamp((x - self.sv_rect.x) / self.sv_rect.width, 0, 1)
        self.value = 1 - MathUtils.clamp((y - self.sv_rect.y) / self.sv_rect.height, 0, 1)
    elseif self.drag_mode == "hue" then
        self.hue = MathUtils.clamp((x - self.hue_rect.x) / self.hue_rect.width, 0, 1)
    elseif self.drag_mode == "alpha" then
        self.alpha = MathUtils.clamp((x - self.alpha_rect.x) / self.alpha_rect.width, 0, 1)
    else
        return false
    end
    self:updateHex()
    return true
end

function EditorColorPicker:apply()
    if self.on_apply and self.on_apply(ColorUtils.RGBAToHex(self:getColor())) == false then return false end
    return self.editor:closeColorPicker(true)
end

function EditorColorPicker:cancel()
    return self.editor:closeColorPicker(false)
end

function EditorColorPicker:onMousePressed(x, y, button, _, presses)
    if button ~= 1 then return true end
    local target = self:getControlAt(x, y)
    if target and target ~= self then
        if target.focusable then self:setFocus(target) else self:setFocus(nil) end
        local local_x, local_y = target:toLocal(x, y)
        if target:onMousePressed(local_x, local_y, button, presses) then self.captured_control = target end
        return true
    end
    self:setFocus(nil)
    if MathUtils.pointInRect(x, y, self.sv_rect) then self.drag_mode = "sv"
    elseif MathUtils.pointInRect(x, y, self.hue_rect) then self.drag_mode = "hue"
    elseif MathUtils.pointInRect(x, y, self.alpha_rect) then self.drag_mode = "alpha"
    elseif x < self.panel_x or y < self.panel_y
        or x >= self.panel_x + self.panel_width or y >= self.panel_y + self.panel_height then
        return self:cancel()
    end
    return self:updateDrag(x, y) or true
end

function EditorColorPicker:onMouseMoved(x, y, dx, dy)
    if self.captured_control then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        self.captured_control:onMouseMoved(local_x, local_y, dx, dy)
    elseif self.drag_mode then
        self:updateDrag(x, y)
    end
    return true
end

function EditorColorPicker:onMouseReleased(x, y, button, _, presses)
    if self.captured_control then
        local target = self.captured_control
        local local_x, local_y = target:toLocal(x, y)
        target:onMouseReleased(local_x, local_y, button, presses)
        self.captured_control = nil
    end
    if button == 1 then self.drag_mode = nil end
    return true
end

function EditorColorPicker:onKeyPressed(key, is_repeat)
    if key == "escape" then return self:cancel() end
    if key == "tab" then
        local controls = { self.hex_input, self.apply_button, self.cancel_button }
        local index = 0
        for candidate, control in ipairs(controls) do
            if control == self.focused_control then index = candidate break end
        end
        index = ((index - 1 + (Input.shift() and -1 or 1)) % #controls) + 1
        self:setFocus(controls[index])
        return true
    end
    if self.focused_control and self.focused_control:onKeyPressed(key, is_repeat) then return true end
    if (key == "return" or key == "kpenter") and not is_repeat then return self:apply() end
    return true
end

function EditorColorPicker:onKeyReleased(key)
    if self.focused_control then self.focused_control:onKeyReleased(key) end
    return true
end

function EditorColorPicker:onTextInput(text)
    if self.focused_control then self.focused_control:onTextInput(text) end
    return true
end

function EditorColorPicker:onWheelMoved()
    return true
end

function EditorColorPicker:getCursorType(x, y)
    if MathUtils.pointInRect(x, y, self.sv_rect) then return "crosshair" end
    if MathUtils.pointInRect(x, y, self.hue_rect) or MathUtils.pointInRect(x, y, self.alpha_rect) then return "select" end
    local target = self:getControlAt(x, y)
    return target and target.cursor_type or "default"
end

function EditorColorPicker:drawSelf()
    Draw.setColor(0, 0, 0, 0.68)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.105, 0.105, 0.125, 1)
    love.graphics.rectangle("fill", self.panel_x, self.panel_y,
        self.panel_width, self.panel_height, 4)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", self.panel_x + 0.5, self.panel_y + 0.5,
        self.panel_width - 1, self.panel_height - 1, 4)
    love.graphics.setFont(EditorFont.get(24))
    Draw.setColor(0.94, 0.94, 0.97, 1)
    love.graphics.print("Choose Color", self.panel_x + 18, self.panel_y + 14)

    local hue_red, hue_green, hue_blue = ColorUtils.HSVToRGB(self.hue, 1, 1)
    Draw.setColor(hue_red, hue_green, hue_blue, 1)
    love.graphics.rectangle("fill", self.sv_rect.x, self.sv_rect.y,
        self.sv_rect.width, self.sv_rect.height)
    drawGradientMesh(self.saturation_mesh, self.sv_rect)
    drawGradientMesh(self.value_mesh, self.sv_rect)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.circle("line", self.sv_rect.x + self.saturation * self.sv_rect.width,
        self.sv_rect.y + (1 - self.value) * self.sv_rect.height, 6)

    drawGradientMesh(self.hue_mesh, self.hue_rect)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.hue_rect.x + self.hue * self.hue_rect.width - 2,
        self.hue_rect.y - 2, 4, self.hue_rect.height + 4)

    Draw.checkerboard(self.alpha_rect.x, self.alpha_rect.y, self.alpha_rect.width, self.alpha_rect.height)
    local color = self:getColor()
    drawGradientMesh(self.alpha_mesh, self.alpha_rect)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.alpha_rect.x + self.alpha * self.alpha_rect.width - 2,
        self.alpha_rect.y - 2, 4, self.alpha_rect.height + 4)

    Draw.checkerboard(self.preview_rect.x, self.preview_rect.y, self.preview_rect.width, self.preview_rect.height)
    Draw.setColor(color)
    love.graphics.rectangle("fill", self.preview_rect.x, self.preview_rect.y,
        self.preview_rect.width, self.preview_rect.height)
    Draw.setColor(0.55, 0.57, 0.64, 1)
    love.graphics.rectangle("line", self.preview_rect.x + 0.5, self.preview_rect.y + 0.5,
        self.preview_rect.width - 1, self.preview_rect.height - 1)
    love.graphics.setFont(EditorFont.get(14))
    Draw.setColor(0.74, 0.76, 0.82, 1)
    love.graphics.print("Hue", self.hue_rect.x, self.hue_rect.y - 17)
    love.graphics.print("Alpha", self.alpha_rect.x, self.alpha_rect.y - 17)
    love.graphics.printf(string.format("H %d\nS %d%%\nV %d%%\nA %d%%",
        MathUtils.round(self.hue * 360), MathUtils.round(self.saturation * 100),
        MathUtils.round(self.value * 100), MathUtils.round(self.alpha * 100)),
        self.preview_rect.x, self.preview_rect.y + 84, self.preview_rect.width, "left")
end

return EditorColorPicker
