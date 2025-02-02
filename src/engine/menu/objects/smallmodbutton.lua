---@class SmallModButton : ModButton
---@overload fun(...) : SmallModButton
local SmallModButton, super = Class(ModButton)

function SmallModButton:setName(name)
    self.name = name
end

function SmallModButton:setSubtitle(subtitle)
    self.subtitle = subtitle
end

function SmallModButton:hasSubtitle()
    return self.subtitle and self.subtitle ~= ""
end

function SmallModButton:onSelect()
    self.selected = true
    if self.preview_script and self.preview_script.onSelect then
        self.preview_script:onSelect(self)
    end
    MainMenu.heart.color = {Kristal.getSoulColor()}
    if MainMenu.mod_list:getSelectedMod() and MainMenu.mod_list:getSelectedMod().soulColor then
        MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
    end
end

function SmallModButton:getHeartPos()
    return self.width/ 2, self.height - 10
end

function SmallModButton:getIconPos()
    return 0, 0
end

function SmallModButton:draw()
    -- Get the position for the mod icon
    local ix, iy = self:getIconPos()

    -- Draw the transparent backgrounds
    Draw.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- Draw the icon background
    love.graphics.rectangle("fill", ix, iy, self.height, self.height)

    -- Draw the rectangle outlines
    self:drawCoolRectangle(ix, iy, self.width, self.height)

    -- Draw favorites star at the heart position
    if self:isFavorited() then
        local star_x, star_y = 8,8
        local star_tex = Assets.getTexture("kristal/menu_star")
        Draw.setColor(self:getDrawColor())
        Draw.draw(star_tex, star_x - star_tex:getWidth()/2, star_y - star_tex:getHeight()/2)
    end


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

    -- Draw text inside the button rectangle
    Draw.pushScissor()
    Draw.scissor(0, 0, self.width, self.height)
    local subh = self:hasSubtitle() and self.subfont:getHeight() or 0
    -- Make name position higher if we have a subtitle
    local name_y = math.floor((self.height/2 - self.font:getHeight()/2) / 2) * 2 - (subh/2)
    love.graphics.setFont(self.font)

    -- Set the font to the small font
    love.graphics.setFont(self.subfont)
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

end

return SmallModButton