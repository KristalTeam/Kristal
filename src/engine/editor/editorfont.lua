local EditorFont = {}

local default_fonts = {}

local function fontSize(size)
    size = size or 16
    local editor = Kristal and Kristal.States and Kristal.States["Editor"]
    return math.max(6, MathUtils.round(size)), editor
end

function EditorFont.get(size)
    local editor
    size, editor = fontSize(size)
    if not editor or editor.use_deltarune_font ~= false then
        return Assets.getFont("main", size)
    end
    if not default_fonts[size] then
        default_fonts[size] = love.graphics.newFont(size)
    end
    return default_fonts[size]
end

function EditorFont.getMono(size)
    local editor
    size, editor = fontSize(size)
    if not editor or editor.use_deltarune_font ~= false then
        return Assets.getFont("main_mono", size)
    end
    if not default_fonts[size] then
        default_fonts[size] = love.graphics.newFont(size)
    end
    return default_fonts[size]
end

return EditorFont
