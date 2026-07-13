---@class EditorImagePreview : EditorControl
---@overload fun(): EditorImagePreview
local EditorImagePreview, super = Class(EditorControl)

function EditorImagePreview:init()
    super.init(self, 0, 0, 0, 0)
    self.document = nil
    self.enabled = false
    self.clip = true
end

function EditorImagePreview:setDocument(document)
    self.document = document
end

function EditorImagePreview:drawSelf()
    Draw.setColor(0.055, 0.055, 0.065, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local document = self.document
    if not document or not document.image then return end

    local padding = 20
    local available_width = math.max(1, self.width - padding * 2)
    local available_height = math.max(1, self.height - padding * 2)
    local scale = math.min(available_width / document.width, available_height / document.height)
    scale = math.max(0.01, math.min(scale, 16))
    local draw_width, draw_height = document.width * scale, document.height * scale
    local x, y = (self.width - draw_width) / 2, (self.height - draw_height) / 2

    Draw.setColor(0.12, 0.12, 0.14, 1)
    love.graphics.rectangle("fill", x - 1, y - 1, draw_width + 2, draw_height + 2)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.draw(document.image, x, y, 0, scale, scale)
    Draw.setColor(0.32, 0.35, 0.43, 1)
    love.graphics.rectangle("line", math.floor(x) + 0.5, math.floor(y) + 0.5,
        math.max(0, math.floor(draw_width) - 1), math.max(0, math.floor(draw_height) - 1))
end

return EditorImagePreview
