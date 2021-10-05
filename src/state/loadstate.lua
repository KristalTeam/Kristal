local LoadState = {}

function LoadState:init()
    self.logo = love.graphics.newImage("assets/sprites/kristal/title_logo.png")
end

function LoadState:enter(from, dir)
    love.thread.newThread("src/loadthread.lua"):start()
    self.channel = love.thread.getChannel("assets")
    self.complete = false
    self.wait_time = 2
end

function LoadState:update(dt)
    self.wait_time = self.wait_time - dt
    if self.complete and self.wait_time <= 0 then
        Gamestate.pop()
    end
    if not self.complete then
        local data = self.channel:pop()
        if data ~= nil then
            Assets:loadData(data.assets)
            Data:loadData(data.data)
            self.complete = true
        end
    end
end

function LoadState:draw()
    love.graphics.draw(self.logo, WIDTH/2, HEIGHT/2, math.sin(self.wait_time * 3) / 5, 1, 1, self.logo:getWidth()/2, self.logo:getHeight()/2)
end

return LoadState