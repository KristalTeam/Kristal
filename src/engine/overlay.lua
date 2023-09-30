---@class Kristal.Overlay
local Overlay = {}

---@param val boolean
function Overlay.setLoading(val)
    Overlay.loading = val
end

function Overlay:init()
    self.quit_frames = {
        love.graphics.newImage("assets/sprites/ui/quit_1.png"),
        love.graphics.newImage("assets/sprites/ui/quit_2.png"),
        love.graphics.newImage("assets/sprites/ui/quit_3.png"),
        love.graphics.newImage("assets/sprites/ui/quit_4.png"),
        love.graphics.newImage("assets/sprites/ui/quit_5.png"),
    }
    self.load_frames = {
        love.graphics.newImage("assets/sprites/ui/loading_1.png"),
        love.graphics.newImage("assets/sprites/ui/loading_2.png"),
        love.graphics.newImage("assets/sprites/ui/loading_3.png"),
        love.graphics.newImage("assets/sprites/ui/loading_4.png"),
        love.graphics.newImage("assets/sprites/ui/loading_5.png"),
    }

    self.font = love.graphics.newFont("assets/fonts/main.ttf", 32)

    self.quit_alpha = 0
    self.load_alpha = 0

    self.quit_timer = 0
    self.load_timer = 0

    self.loading = false

    self.quit_release = false
end

function Overlay:update()
    if self.loading then
        if self.load_alpha < 1 then
            self.load_alpha = math.min(1, self.load_alpha + DT / 0.25)
        end
        self.load_timer = self.load_timer + DT
    else
        if self.load_alpha > 0 then
            self.load_alpha = math.max(0, self.load_alpha - DT / 0.25)
        end
        self.load_timer = 0
    end

    if love.keyboard.isDown("escape") and not self.quit_release then
        if self.quit_alpha < 1 then
            self.quit_alpha = math.min(1, self.quit_alpha + DT / 0.75)
        end
        self.quit_timer = self.quit_timer + DT
        if self.quit_timer > 1.2 then
            if Mod ~= nil then
                self.quit_release = true
                if Kristal.getModOption("hardReset") then
                    love.event.quit("restart")
                else
                    Kristal.returnToMenu()
                end
            else
                love.event.quit()
            end
        end
    else
        self.quit_timer = 0
        if self.quit_alpha > 0 then
            self.quit_alpha = math.max(0, self.quit_alpha - DT / 0.25)
        end
    end

    if self.quit_release and not love.keyboard.isDown("escape") then
        self.quit_release = false
    end
end

function Overlay:draw()
    -- Draw the quit text
    love.graphics.push()
    love.graphics.scale(2)
    Draw.setColor(1, 1, 1, self.quit_alpha)
    local quit_frame = (math.floor(self.quit_timer / 0.25) % #self.quit_frames) + 1
    Draw.draw(self.quit_frames[quit_frame])
    love.graphics.pop()

    -- Draw the load text
    love.graphics.push()
    love.graphics.translate(0, SCREEN_HEIGHT)
    love.graphics.scale(2)
    Draw.setColor(1, 1, 1, self.load_alpha)
    local load_frame = (math.floor(self.load_timer / 0.25) % #self.load_frames) + 1
    local load_texture = self.load_frames[load_frame]
    Draw.draw(load_texture, 0, -load_texture:getHeight())
    love.graphics.pop()

    -- Draw the loader messages
    if Kristal.Loader.message ~= "" then
        love.graphics.setFont(self.font)
        local text = Kristal.Loader.message
        local x = SCREEN_WIDTH - self.font:getWidth(text) - 2
        local y = SCREEN_HEIGHT - self.font:getHeight() - 4
        Draw.setColor(0, 0, 0)
        for ox = -1, 1 do
            for oy = -1, 1 do
                if ox ~= 0 or oy ~= 0 then
                    love.graphics.print(text, x + (ox * 2), y + (oy * 2))
                end
            end
        end
        Draw.setColor(1, 1, 1)
        love.graphics.print(text, x, y)
    end

    -- Draw the FPS counter text
    if Kristal.Config and Kristal.Config["showFPS"] then
        love.graphics.setFont(self.font)
        local text = FPS .. " FPS"
        local x = SCREEN_WIDTH - self.font:getWidth(text) - 2
        local y = -4
        Draw.setColor(0, 0, 0)
        for ox = -1, 1 do
            for oy = -1, 1 do
                if ox ~= 0 or oy ~= 0 then
                    love.graphics.print(text, x + (ox * 2), y + (oy * 2))
                end
            end
        end
        Draw.setColor(1, 1, 1)
        love.graphics.print(text, x, y)
    end

    -- Reset the color
    Draw.setColor(1, 1, 1, 1)
end

return Overlay
