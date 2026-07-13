---@class EditorCodeHoverPopup : EditorControl
---@overload fun(): EditorCodeHoverPopup
local EditorCodeHoverPopup, super = Class(EditorControl)

local OUTER_PADDING = 6
local SECTION_PADDING = 7
local SECTION_GAP = 6
local DOCUMENTATION_HEADER = 20

local function cleanMarkdown(text)
    text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    text = text:gsub("<br%s*/?>", "\n"):gsub("&nbsp;", " ")
    text = text:gsub("%[([^%]]+)%]%([^%)]+%)", "%1")
    text = text:gsub("^#+%s*", ""):gsub("\n#+%s*", "\n")
    text = text:gsub("\n%s*[%*%-]%s+", "\n- ")
    text = text:gsub("^%s*[%*%-]%s+", "- ")
    text = text:gsub("%*%*", ""):gsub("__", ""):gsub("`", "")
    text = text:gsub("\n\n\n+", "\n\n")
    return StringUtils.trim(text)
end

local function addMarkdown(value, signatures, documentation)
    value = tostring(value or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    value = value:gsub("```([%w_+%-]*)[ \t]*\n(.-)```", function(language, code)
        if language == "" or language:lower() == "lua" then
            code = StringUtils.trim(code)
            if code ~= "" then table.insert(signatures, code) end
            return "\n"
        end
        return code
    end)
    value = cleanMarkdown(value)
    if value ~= "" then table.insert(documentation, value) end
end

local function collectContents(contents, signatures, documentation)
    if type(contents) == "string" then
        addMarkdown(contents, signatures, documentation)
    elseif type(contents) ~= "table" or contents == JSON.null then
        return
    elseif type(contents.value) == "string" then
        if type(contents.language) == "string" then
            local value = StringUtils.trim(contents.value)
            if value ~= "" then table.insert(signatures, value) end
        elseif contents.kind == "markdown" then
            addMarkdown(contents.value, signatures, documentation)
        else
            local value = cleanMarkdown(contents.value)
            if value ~= "" then table.insert(documentation, value) end
        end
    else
        for _, entry in ipairs(contents) do collectContents(entry, signatures, documentation) end
    end
end

function EditorCodeHoverPopup:init()
    super.init(self, 0, 0, 0, 0)
    self.visible = false
    self.clip = true
    self.signature_lines = {}
    self.documentation_lines = {}
    self.documentation_scroll = 0
    self.signature_rect = nil
    self.documentation_rect = nil
end

function EditorCodeHoverPopup:getDocumentationVisibleRows()
    if not self.documentation_rect then return 0 end
    local font = EditorFont.getMono(16)
    local content_height = self.documentation_rect.height - DOCUMENTATION_HEADER - SECTION_PADDING
    return math.max(0, math.floor(content_height / font:getHeight()))
end

function EditorCodeHoverPopup:getMaximumDocumentationScroll()
    return math.max(0, #self.documentation_lines - self:getDocumentationVisibleRows())
end

function EditorCodeHoverPopup:scrollRows(rows)
    if not self.visible or not self.documentation_rect then return false end
    self.documentation_scroll = MathUtils.clamp(self.documentation_scroll + rows,
        0, self:getMaximumDocumentationScroll())
    return true
end

function EditorCodeHoverPopup:onWheelMoved(_, y)
    return self:scrollRows(-y * 3)
end

function EditorCodeHoverPopup:show(hover, anchor_x, anchor_y, parent_width, parent_height)
    local signatures, documentation = {}, {}
    collectContents(hover and hover.contents, signatures, documentation)
    if #signatures == 0 and #documentation == 0 then return self:close() end

    local font = EditorFont.getMono(16)
    local line_height = font:getHeight()
    local width = math.max(120, math.min(540, parent_width - 8))
    local content_width = width - (OUTER_PADDING + SECTION_PADDING) * 2 - 8

    self.signature_lines = {}
    if #signatures > 0 then
        local highlighter = EditorLuaHighlighter(table.concat(signatures, "\n"))
        for index = 1, #highlighter.lines do
            table.insert(self.signature_lines, highlighter:getLine(index))
        end
    end

    self.documentation_lines = {}
    local documentation_text = table.concat(documentation, "\n\n")
    if documentation_text ~= "" then
        local _, wrapped = font:getWrap(documentation_text, math.max(40, content_width))
        self.documentation_lines = wrapped
    end
    self.documentation_scroll = 0

    local signature_height = #self.signature_lines > 0
        and (#self.signature_lines * line_height + SECTION_PADDING * 2) or 0
    local documentation_height = #self.documentation_lines > 0
        and (DOCUMENTATION_HEADER + #self.documentation_lines * line_height + SECTION_PADDING) or 0
    local desired_height = OUTER_PADDING * 2 + signature_height + documentation_height
        + (signature_height > 0 and documentation_height > 0 and SECTION_GAP or 0)

    local below_y = anchor_y + 18
    local below_space = math.max(0, parent_height - below_y - 2)
    local above_space = math.max(0, anchor_y - 8)
    local place_below = desired_height <= below_space or below_space >= above_space
    local available_height = place_below and below_space or above_space
    local height = math.min(desired_height, math.max(70, available_height))
    height = math.min(height, math.max(0, parent_height - 4))
    local x = MathUtils.clamp(anchor_x + 12, 2, math.max(2, parent_width - width - 2))
    local y = place_below and below_y or math.max(2, anchor_y - height - 8)
    self:setBounds(x, y, width, height)

    local section_y = OUTER_PADDING
    self.signature_rect = nil
    if signature_height > 0 then
        local reserved_documentation = documentation_height > 0
            and math.min(documentation_height, math.max(DOCUMENTATION_HEADER + line_height + SECTION_PADDING,
                height - OUTER_PADDING * 2 - SECTION_GAP - signature_height)) or 0
        local available_signature = height - OUTER_PADDING * 2 - reserved_documentation
            - (documentation_height > 0 and SECTION_GAP or 0)
        local actual_signature_height = math.min(signature_height, math.max(line_height + SECTION_PADDING * 2,
            available_signature))
        self.signature_rect = {
            x = OUTER_PADDING, y = section_y,
            width = width - OUTER_PADDING * 2, height = actual_signature_height
        }
        section_y = section_y + actual_signature_height + (documentation_height > 0 and SECTION_GAP or 0)
    end
    self.documentation_rect = nil
    if documentation_height > 0 then
        self.documentation_rect = {
            x = OUTER_PADDING, y = section_y,
            width = width - OUTER_PADDING * 2,
            height = math.max(0, height - section_y - OUTER_PADDING)
        }
    end
    self.visible = true
    return true
end

function EditorCodeHoverPopup:close()
    self.visible = false
    self.signature_lines = {}
    self.documentation_lines = {}
    self.documentation_scroll = 0
    self.signature_rect = nil
    self.documentation_rect = nil
    return true
end

function EditorCodeHoverPopup:drawSignature(font)
    local rect = self.signature_rect
    if not rect then return end
    Draw.setColor(0.085, 0.095, 0.12, 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
    Draw.setColor(0.28, 0.38, 0.56, 1)
    love.graphics.rectangle("line", rect.x + 0.5, rect.y + 0.5, rect.width - 1, rect.height - 1)
    local y = rect.y + SECTION_PADDING
    for _, line in ipairs(self.signature_lines) do
        if y + font:getHeight() > rect.y + rect.height then break end
        local x = rect.x + SECTION_PADDING
        for _, token in ipairs(line) do
            Draw.setColor(EditorLuaHighlighter.COLORS[token.kind] or EditorLuaHighlighter.COLORS.text)
            love.graphics.print(token.text, x, y)
            x = x + font:getWidth(token.text)
        end
        y = y + font:getHeight()
    end
end

function EditorCodeHoverPopup:drawDocumentation(font)
    local rect = self.documentation_rect
    if not rect then return end
    Draw.setColor(0.064, 0.066, 0.078, 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
    Draw.setColor(0.25, 0.27, 0.33, 1)
    love.graphics.rectangle("line", rect.x + 0.5, rect.y + 0.5, rect.width - 1, rect.height - 1)
    Draw.setColor(0.55, 0.62, 0.76, 1)
    love.graphics.print("Documentation", rect.x + SECTION_PADDING, rect.y + 3)

    local first = self.documentation_scroll + 1
    local last = math.min(#self.documentation_lines, first + self:getDocumentationVisibleRows() - 1)
    local y = rect.y + DOCUMENTATION_HEADER
    Draw.setColor(0.86, 0.86, 0.90, 1)
    for index = first, last do
        love.graphics.print(self.documentation_lines[index], rect.x + SECTION_PADDING, y)
        y = y + font:getHeight()
    end

    local maximum = self:getMaximumDocumentationScroll()
    if maximum > 0 then
        local track_x = rect.x + rect.width - 5
        local track_y = rect.y + DOCUMENTATION_HEADER
        local track_height = math.max(4, rect.height - DOCUMENTATION_HEADER - 3)
        local visible = self:getDocumentationVisibleRows()
        local thumb_height = math.max(10, track_height * visible / #self.documentation_lines)
        local thumb_y = track_y + (track_height - thumb_height) * self.documentation_scroll / maximum
        Draw.setColor(0.16, 0.17, 0.20, 1)
        love.graphics.rectangle("fill", track_x, track_y, 3, track_height)
        Draw.setColor(0.45, 0.50, 0.62, 1)
        love.graphics.rectangle("fill", track_x, thumb_y, 3, thumb_height)
    end
end

function EditorCodeHoverPopup:drawSelf()
    Draw.setColor(0.045, 0.047, 0.057, 0.99)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.getMono(16)
    love.graphics.setFont(font)
    self:drawSignature(font)
    self:drawDocumentation(font)
    Draw.setColor(0.34, 0.37, 0.46, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
end

return EditorCodeHoverPopup
