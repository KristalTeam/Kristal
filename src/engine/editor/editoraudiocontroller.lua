--- Manages editor music and preview audio.
---@class EditorAudioController : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorAudioController
local EditorAudioController = Class()

function EditorAudioController:init(editor)
    self.editor = editor
end

local EDITOR_MUSIC = "edit"
local EDITOR_MUSIC_VOLUME = 0.5
local EDITOR_MUSIC_FADE_TIME = 1

local function editorMusicFadeTime(options, fallback)
    local fade = options and tonumber(options.fade)
    return math.max(0, fade or fallback or 0)
end

function EditorAudioController:resetEditingMusic()
    local self = self.editor
    if self.music then self.music:remove() end
    if self.editor_music_override_player then self.editor_music_override_player:remove() end
    self.music = Music()
    self.editor_music_override_player = Music()
    self.editor_music_overrides = {}
    self.editor_music_override_sequence = 0
    self.editor_music_fade_tokens = {}
    self.editing_music_started = false
end

function EditorAudioController:invalidateEditingMusicFade(music)
    local self = self.editor
    local token = (self.editor_music_fade_tokens[music] or 0) + 1
    self.editor_music_fade_tokens[music] = token
    return token
end

function EditorAudioController:fadeEditingMusicOut(music, duration)
    local self = self.editor
    if not music or not music.source then return false end
    local token = self:invalidateEditingMusicFade(music)
    duration = math.max(0, tonumber(duration) or 0)
    if duration == 0 or not music:isPlaying() then
        music:setVolume(0)
        music:pause()
        return true
    end
    music:fade(0, duration, function(handler)
        if self.editor_music_fade_tokens[handler] == token and handler.target_volume == 0 then
            handler:pause()
        end
    end)
    return true
end

function EditorAudioController:fadeEditingMusicIn(music, volume, duration)
    local self = self.editor
    if not music or not music.source then return false end
    self:invalidateEditingMusicFade(music)
    if music:canResume() then music:resume() end
    duration = math.max(0, tonumber(duration) or 0)
    if duration == 0 then
        music:setVolume(volume)
    else
        music:fade(volume, duration)
    end
    return true
end

function EditorAudioController:resumeEditingMusic(fade_time)
    local self = self.editor
    if not self.editing_music_started then
        self.music:play(EDITOR_MUSIC, 0)
        if not self.music.source then return false end
        self.editing_music_started = true
    elseif self.music:canResume() then
        self.music:resume()
    end
    self:fadeEditingMusicIn(self.music, EDITOR_MUSIC_VOLUME,
        fade_time == nil and EDITOR_MUSIC_FADE_TIME or fade_time)
    return true
end

function EditorAudioController:pauseEditingMusic(fade_time)
    local self = self.editor
    return self:fadeEditingMusicOut(self.music, fade_time or 0)
end

function EditorAudioController:stopBaseEditingMusic()
    local self = self.editor
    if self.music then
        self:invalidateEditingMusicFade(self.music)
        self.music:stop()
    end
    self.editing_music_started = false
end

function EditorAudioController:stopEditingMusic()
    local self = self.editor
    self:stopBaseEditingMusic()
    if self.editor_music_override_player then
        self:invalidateEditingMusicFade(self.editor_music_override_player)
        self.editor_music_override_player:stop()
    end
    self.editor_music_overrides = {}
    self.active_editor_music_override = nil
end

function EditorAudioController:setEditorMusicOverride(owner, music, options)
    local self = self.editor
    assert(owner ~= nil, "Editor music overrides require an owner")
    assert(music == false or type(music) == "string" and music ~= "",
        "Editor music overrides require a music id or false for silence")
    options = TableUtils.copy(options or {}, false)
    self.editor_music_override_sequence = self.editor_music_override_sequence + 1
    local request = {
        owner = owner,
        music = music,
        volume = math.max(0, tonumber(options.volume) or 1),
        pitch = tonumber(options.pitch) or 1,
        looping = options.looping ~= false,
        fade = editorMusicFadeTime(options, EDITOR_MUSIC_FADE_TIME),
        sequence = self.editor_music_override_sequence
    }
    self.editor_music_overrides[owner] = request
    self:syncEditingMusic({ fade = request.fade })
    return request
end

function EditorAudioController:clearEditorMusicOverride(owner, options)
    local self = self.editor
    local request = self.editor_music_overrides and self.editor_music_overrides[owner]
    if not request then return false end
    self.editor_music_overrides[owner] = nil
    if not options or options.sync ~= false then
        self:syncEditingMusic({ fade = editorMusicFadeTime(options, request.fade) })
    end
    return true
end

function EditorAudioController:getActiveEditorMusicOverride()
    local self = self.editor
    local active
    for _, request in pairs(self.editor_music_overrides or {}) do
        if not active or request.sequence > active.sequence then active = request end
    end
    return active
end

function EditorAudioController:resumeEditorMusicOverride(request, fade_time)
    local self = self.editor
    local player = self.editor_music_override_player
    if not player then return false end
    player:setLooping(request.looping)
    if player.current ~= request.music or not player.source then
        player:play(request.music, 0, request.pitch)
    else
        player:setPitch(request.pitch)
        if player:canResume() then player:resume() end
    end
    if not player.source then return false end
    return self:fadeEditingMusicIn(player, request.volume, fade_time)
end

function EditorAudioController:syncEditingMusic(options)
    local self = self.editor
    local preview_running = self.live_document ~= nil
        and not self.game_preview_paused
        and not self.game_faulted
        and not self.exit_transition
    if preview_running then
        self:pauseEditingMusic(0)
        self:fadeEditingMusicOut(self.editor_music_override_player, 0)
        return
    end

    local request = self:getActiveEditorMusicOverride()
    self.active_editor_music_override = request
    local fade_time = editorMusicFadeTime(options,
        request and request.fade or EDITOR_MUSIC_FADE_TIME)
    if request then
        if request.music == false then
            self:pauseEditingMusic(fade_time)
            self:fadeEditingMusicOut(self.editor_music_override_player, fade_time)
            return
        end
        if self:resumeEditorMusicOverride(request, fade_time) then
            self:pauseEditingMusic(fade_time)
            return
        end
    else
        self:fadeEditingMusicOut(self.editor_music_override_player, fade_time)
    end

    if self.editor_music_enabled == false then
        self:stopBaseEditingMusic()
    else
        self:resumeEditingMusic(fade_time)
    end
end

function EditorAudioController:setEditingMusicEnabled(enabled)
    local self = self.editor
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.editor_music") then
        return self.settings:setValue("appearance.editor_music", enabled)
    end
    self.editor_music_enabled = enabled
    self:syncEditingMusic()
end

return EditorAudioController
