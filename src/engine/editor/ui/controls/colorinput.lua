---@class EditorColorInput : EditorControl
---@overload fun(editor: Editor, value?: string|table, options?: table): EditorColorInput
local EditorColorInput, super = Class(EditorControl)

local ColorSwatchButton, button_super = Class(EditorButton)

local function colorValue(value)
    if type(value) == "table" then return ColorUtils.RGBAToHex(value) end
    value = tostring(value or "")
    local hex = value:gsub("^#", "")
    if (#hex ~= 6 and #hex ~= 8) or not hex:match("^%x+$") then return nil end
    local color = ColorUtils.tryHexToRGB(value)
    return color and ("#" .. hex:upper()) or nil
end

local function drawCheckerboard(width, height, size)
    size = size or 6
    for y = 0, math.ceil(height / size) - 1 do
        for x = 0, math.ceil(width / size) - 1 do
            local value = (x + y) % 2 == 0 and 0.72 or 0.42
            Draw.setColor(value, value, value, 1)
            love.graphics.rectangle("fill", x * size, y * size,
                math.min(size, width - x * size), math.min(size, height - y * size))
        end
    end
end

function ColorSwatchButton:init(on_pressed, get_color)
    button_super.init(self, "", on_pressed)
    self.get_color = get_color
end

function ColorSwatchButton:drawSelf()
    drawCheckerboard(self.width, self.height)
    local color = self.get_color and self.get_color()
    if color then
        Draw.setColor(color)
        love.graphics.rectangle("fill", 2, 2, self.width - 4, self.height - 4)
    end
    Draw.setColor(self.focused and { 0.55, 0.68, 0.90, 1 } or { 0.32, 0.32, 0.37, 1 })
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
end

function EditorColorInput:init(editor, value, options)
    options = options or {}
    super.init(self, 0, 0, options.width or 180, 28)
    self.editor = editor
    self.on_submit = options.on_submit
    self.value = colorValue(value) or "#FFFFFFFF"
    self.swatch = self:addChild(ColorSwatchButton(function() self:openPicker() end,
        function() return ColorUtils.tryHexToRGB(self.value) end))
    self.input = self:addChild(EditorTextInput({
        editor = editor,
        placeholder = "#RRGGBB or #RRGGBBAA",
        on_submit = function(input) return self:submitValue(input) end
    }))
    self.inputs = { self.input }
    self.input:setValue(self.value, true)
    self.preferred_height = 28
end

function EditorColorInput:setValue(value, silent)
    local normalized = colorValue(value)
    if not normalized then return false end
    self.value = normalized
    self.input:setValue(normalized, silent == true)
    return true
end

function EditorColorInput:submitValue(value)
    local normalized = colorValue(value)
    if not normalized then return false end
    if self.on_submit and self.on_submit(normalized, self) == false then return false end
    self.value = normalized
    self.input:setValue(normalized, true)
    return true
end

function EditorColorInput:openPicker()
    if not self.editor then return false end
    return self.editor:openColorPicker(self.value, function(value)
        return self:submitValue(value)
    end) ~= nil
end

function EditorColorInput:update(dt)
    local swatch_width = math.min(34, self.width)
    self.swatch:setBounds(0, 0, swatch_width, self.height)
    self.input:setBounds(swatch_width + 5, 0, math.max(0, self.width - swatch_width - 5), self.height)
    super.update(self, dt)
end

return EditorColorInput
