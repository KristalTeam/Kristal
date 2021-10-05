local LoadState = {}

function LoadState:init()
    self.logo = love.graphics.newImage("assets/sprites/kristal/title_logo.png")
end

function LoadState:enter(from, dir)
    self.drawn = false
    self.load_dir = dir
end

function LoadState:update()
    if self.drawn then
        Assets:load(self.load_dir)
        Gamestate.pop()
    end
end

function LoadState:draw()
    love.graphics.draw(self.logo, WIDTH/2, HEIGHT/2, 0, 1, 1, self.logo:getWidth()/2, self.logo:getHeight()/2)
    self.drawn = true
end

return LoadState