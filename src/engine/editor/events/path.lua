---@class EditorPath : EditorEvent
---@overload fun(data?: table, options?: table): EditorPath
local EditorPath = Class(EditorEvent)

EditorPath.placement_shape = "region"
EditorPath.runtime_type = "path"

function EditorPath:createObject()
    return nil
end

function EditorPath:getTexture()
    return nil, false
end

function EditorPath:drawPreviewIcon(x, y, width, height, alpha)
    local texture = Assets.getTexture("editor/ui/layer/paths")
    if not texture then return false end
    local scale = math.min(width / texture:getWidth(), height / texture:getHeight())
    Draw.setColor(1, 0.35, 0.85, alpha or 1)
    Draw.draw(texture, x + width / 2, y + height / 2, 0, scale, scale,
        texture:getWidth() / 2, texture:getHeight() / 2)
    Draw.setColor(1, 1, 1, 1)
    return true
end

return EditorPath
