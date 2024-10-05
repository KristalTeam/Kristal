---@class ModButton : Object
---@overload fun(...) : ModButton
local ModButton, super = Class(Object)

function ModButton:init(name, width, height, mod)
    super.init(self, 0, 0, width, height)

    self.name = name
    self.mod = mod
    self.id = mod and mod.id or name

    self.subtitle = mod and mod.subtitle
    self.version = mod and mod.version or ""

    self.icon = mod and mod.icon or {Assets.getTexture("kristal/mod_icon")}
    self.icon_delay = mod and mod.iconDelay or 0.25
    self.icon_frame = 1

    self.favorited_color = {1, 1, 0.7, 1}

    self.engine_versions = {}
    local engine_ver = mod and mod.engineVer
    if type(engine_ver) == "table" then
        for _,ver in ipairs(engine_ver) do
            table.insert(self.engine_versions, SemVer(ver))
        end
    elseif type(engine_ver) == "string" then
        self.engine_versions = {SemVer(engine_ver)}
    else
        self.engine_versions = {Kristal.Version}
    end

    self.selected = false

    -- temporary
    self.font = Assets.getFont("main")
    self.subfont = Assets.getFont("main", 16)
end

function ModButton:setName(name)
    self.name = name
end

function ModButton:setSubtitle(subtitle)
    self.subtitle = subtitle
end

function ModButton:hasSubtitle()
    return self.subtitle and self.subtitle ~= ""
end

function ModButton:onSelect()
    self.selected = true
    if self.preview_script and self.preview_script.onSelect then
        self.preview_script:onSelect(self)
    end
	MainMenu.heart.color = {Kristal.getSoulColor()}
	if MainMenu.mod_list:getSelectedMod().soulColor then
		MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
	end
end

function ModButton:onDeselect()
    self.selected = false
    if self.preview_script and self.preview_script.onDeselect then
        self.preview_script:onDeselect(self)
    end
end

function ModButton:setFavoritedColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = unpack(r)
    end
    local r1, g1, b1, a1 = super.getDrawColor(self)
    self.favorited_color = {r or r1, g or g1, b or b1, a or a1}
end

function ModButton:getFavoritedColor()
    local r, g, b, a = super.getDrawColor(self)
    return self.favorited_color[1] or r, self.favorited_color[2] or g, self.favorited_color[3] or b, self.favorited_color[4] or a
end

function ModButton:getDrawColor()
    local r, g, b, a = super.getDrawColor(self)
    if self:isFavorited() then
        r, g, b, a = self.favorited_color[1] or r, self.favorited_color[2] or g, self.favorited_color[3] or b, self.favorited_color[4] or a
    end
    if not self.selected then
        return r * 0.6, g * 0.6, b * 0.7, a
    else
        return r, g, b, a
    end
end

function ModButton:getHeartPos()
    return 29, self.height / 2
end

function ModButton:getIconPos()
    return self.width + 8, 0
end

function ModButton:checkCompatibility()
    local success = false
    local highest_version
    for _,version in ipairs(self.engine_versions) do
        if not highest_version or highest_version < version then
            highest_version = version
        end
        if version ^ Kristal.Version then
            success = true
        end
    end
    return success, highest_version
end

function ModButton:isFavorited()
    return Utils.containsValue(Kristal.Config["favorites"], self.id)
end

function ModButton:drawCoolRectangle(x, y, w, h)
    -- Make sure the line is a single pixel wide
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    -- Set the color
    Draw.setColor(self:getDrawColor())
    -- Draw the rectangles
    love.graphics.rectangle("line", x, y, w + 1, h + 1)
    -- Increase the width and height by one instead of two to produce the broken effect
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2)
    love.graphics.rectangle("line", x - 2, y - 2, w + 5, h + 5)
    -- Here too
    love.graphics.rectangle("line", x - 3, y - 3, w + 6, h + 6)
end

function ModButton:update()
    if self.selected then
        self.icon_frame = self.icon_frame + (DT / math.max(1/60, self.icon_delay))
        if math.floor(self.icon_frame) > #self.icon then
            self.icon_frame = 1
        end
    else
        self.icon_frame = 1
    end

    super.update(self)
end

function ModButton:draw()
    -- Get the position for the mod icon
    local ix, iy = self:getIconPos()

    -- Draw the transparent backgrounds
    Draw.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- Draw the icon background
    love.graphics.rectangle("fill", ix, iy, self.height, self.height)

    -- Draw the rectangle outlines
    self:drawCoolRectangle(0, 0, self.width, self.height)
    self:drawCoolRectangle(ix, iy, self.height, self.height)

    -- Draw favorites star at the heart position
    if self:isFavorited() and not self.selected then
        local star_x, star_y = self:getHeartPos()
        local star_tex = Assets.getTexture("kristal/menu_star")
        Draw.setColor(self:getDrawColor())
        Draw.draw(star_tex, star_x - star_tex:getWidth()/2, star_y - star_tex:getHeight()/2)
    end

    -- Draw text inside the button rectangle
    Draw.pushScissor()
    Draw.scissor(0, 0, self.width, self.height)
    local subh = self:hasSubtitle() and self.subfont:getHeight() or 0
    -- Make name position higher if we have a subtitle
    local name_y = math.floor((self.height/2 - self.font:getHeight()/2) / 2) * 2 - (subh/2)
    love.graphics.setFont(self.font)
    -- Draw the name shadow
    Draw.setColor(0, 0, 0)
    love.graphics.print(self.name, 50 + 2, name_y + 2)
    -- Draw the name
    Draw.setColor(self:getDrawColor())
    love.graphics.print(self.name, 50, name_y)

    -- Set the font to the small font
    love.graphics.setFont(self.subfont)
    if self:hasSubtitle() then
        -- Draw the subtitle shadow
        Draw.setColor(0, 0, 0)
        love.graphics.print(self.subtitle, 50 + 1, name_y + self.font:getHeight() + 1)
        -- Draw the subtitle
        Draw.setColor(self:getDrawColor())
        love.graphics.print(self.subtitle, 50, name_y + self.font:getHeight())
    end
    -- Calculate version position
    local ver_compat = self:checkCompatibility()
    local ver_name = ver_compat and self.version or (self.version.." (!)")
    local ver_x = self.width - 4 - self.subfont:getWidth(ver_name)
    local ver_y = 0
    -- Draw the version shadow
    Draw.setColor(0, 0, 0)
    love.graphics.print(ver_name, ver_x + 1, ver_y + 1)
    -- Draw the version
    if self:checkCompatibility() then
        local r,g,b,a = self:getDrawColor()
        Draw.setColor(r, g, b, a)
    else
        local r,g,b,a = self:getDrawColor()
        -- Slight yellow
        Draw.setColor(r, g*0.75, b*0.75, a)
    end
    love.graphics.print(ver_name, ver_x, ver_y)

    Draw.popScissor()

    -- Draw icon
    local icon = self.icon[math.floor(self.icon_frame)]
    if icon then
        local x, y = ix + self.height/2 - icon:getWidth(), iy + self.height/2 - icon:getHeight()
        -- Draw the icon shadow
        Draw.setColor(0, 0, 0)
        Draw.draw(icon, x + 2, y + 2, 0, 2, 2)
        -- Draw the icon
        Draw.setColor(self:getDrawColor())
        Draw.draw(icon, x, y, 0, 2, 2)
    end
end

return ModButton