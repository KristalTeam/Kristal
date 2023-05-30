---@class Video : Object
---@overload fun(...) : Video
local Video, super = Class(Object)

function Video:init(video, load_audio, x, y, w, h)
    self.video = Assets.newVideo(video, load_audio)

    self.video_width = self.video:getWidth()
    self.video_height = self.video:getHeight()

    if not w and not h then
        w, h = self.video_width, self.video_height
    end

    super.init(self, x, y, w, h)

    self.queued_play = false
    self.looping = false
    self.was_playing = false
end

function Video:play()
    if not self.stage then
        self.queued_play = true
    else
        self.video:play()
        self.was_playing = true
    end
end

function Video:stop()
    self.queued_play = false
    self.was_playing = false
    self.video:pause()
    self.video:rewind()
end

function Video:pause()
    self.queued_play = false
    self.was_playing = false
    self.video:pause()
end

function Video:rewind()
    self.video:rewind()
end

function Video:seek(time)
    self.video:seek(time)
end

function Video:tell()
    return self.video:tell()
end

function Video:isPlaying()
    return self.video:isPlaying()
end

function Video:setLooping(loop)
    self.looping = loop or false
end

function Video:onRemoveFromStage(stage)
    super.onRemoveFromStage(self, stage)

    if self.video:isPlaying() then
        self.video:pause()
    end
end

function Video:update()
    if self.queued_play then
        self.queued_play = false
        if not self.video:isPlaying() then
            self.video:play()
        end
    end

    if self.looping and self.was_playing and not self.video:isPlaying() then
        self.video:rewind()
        self.video:play()
    end

    super.update(self)

    self.was_playing = self.video:isPlaying()
end

function Video:draw()
    local scale_x, scale_y = self.width / self.video_width, self.height / self.video_height
    Draw.draw(self.video, 0, 0, 0, scale_x, scale_y)

    super.draw(self)
end

return Video