local Testing = {}

function Testing:enter()
    self.stage = Stage()

    self.frame = 0

    self.stage.timer:script(function(wait)
        while true do
            print("frame[t]", self.frame)
            wait()
        end
    end)
end

function Testing:update(dt)
    print("-----")

    self.frame = self.frame + 1

    self.stage:update(dt)

    print("frame[u]", self.frame)
end

return Testing