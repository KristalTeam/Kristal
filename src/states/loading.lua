local loadstate = {}

function loadstate:init()
    self.logo = love.graphics.newImage("assets/sprites/kristal/title_logo.png")
end

function loadstate:enter(from, dir)
    love.thread.newThread("src/loadthread.lua"):start()
    self.channel = love.thread.getChannel("assets")
    self.complete = false
    self.wait_time = 2
end

function loadstate:update(dt)
    self.wait_time = self.wait_time - dt
    if self.complete and self.wait_time <= 0 then
        kristal.states.switch(kristal.states.menu)
    end
    if not self.complete then
        local data = self.channel:pop()
        if data ~= nil then
            kristal.assets.loadData(data.assets)
            kristal.data.loadData(data.data)
            self.complete = true
        end
    end
end

function loadstate:draw()
    love.graphics.draw(self.logo, WIDTH/2, HEIGHT/2, math.sin(self.wait_time * 3) / 5, 1, 1, self.logo:getWidth()/2, self.logo:getHeight()/2)
end

return loadstate