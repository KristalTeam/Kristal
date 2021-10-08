local preview = {}

-- whether to fade out the default background
preview.hide_background = false

function preview:init()
    -- code here gets called when the mods are loaded

    self.vignette_canvas = love.graphics.newCanvas(WIDTH, HEIGHT)
    self.timer = 0
end

function preview:update(dt)
    -- code here gets called every frame, before any draws
    -- to only update while the mod is selected, check self.selected (or self.fade)
    self.timer = self.timer + dt
end

function preview:draw()
    -- code here gets drawn to the background every frame!!
    -- make sure to check  self.fade  or  self.selected  here
    love.graphics.setColor(0, 0, 0, self.fade * 0.5)
    love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
end

function preview:drawOverlay()
    -- code here gets drawn above the menu every frame
    -- so u can make cool effects
    -- if u want

    love.graphics.setCanvas(self.vignette_canvas)
    love.graphics.clear(0, 0, 0, self.fade)

    local radius_from = 320
    local radius_to = 32

    local radius = radius_from + (radius_to - radius_from) * self.fade
    radius = radius + math.sin(self.timer * 4) * (radius / 4)

    local x, y = kristal.states.menu.heart_x, kristal.states.menu.heart_y

    love.graphics.setBlendMode("replace")

    local circles = 24
    for i = circles, 0, -1 do
        love.graphics.setColor(0, 0, 0, self.fade * (i / circles))
        love.graphics.circle("fill", x + 8, y + 8, radius + (i * 16))
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setBlendMode("alpha")

    love.graphics.draw(self.vignette_canvas)
end

return preview