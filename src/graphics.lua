local graphics = {}

graphics._canvases = {}
graphics._keep_canvas = {}
graphics._used_canvas = {}

function graphics.getCanvas(id, width, height, keep)
    graphics._used_canvas[id] = true
    graphics._keep_canvas[id] = keep
    local canvas = graphics._canvases[id]
    if not canvas or canvas[2] ~= width or canvas[3] ~= height then
        canvas = {love.graphics.newCanvas(width, height), width, height}
        graphics._canvases[id] = canvas
    end
    return canvas[1]
end

function graphics._clearUnusedCanvases()
    local remove = {}
    for k,_ in pairs(graphics._canvases) do
        if not graphics._keep_canvas[k] and not graphics._used_canvas[k] then
            table.insert(remove, k)
        end
    end
    for _,v in ipairs(remove) do
        graphics._canvases[v][1] = nil
        graphics._canvases[v] = nil
    end
end

return graphics