---@class Actor : Class
---@overload fun(...) : Actor
local Actor = Class()

function Actor:init()
    -- Display name (optional)
    self.name = nil

    -- Width and height for this actor, used to determine its center
    self.width = 0
    self.height = 0

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = nil

    -- A table that defines where the Soul should be placed on this actor if they are a player.
    -- First value is x, second value is y.
    self.soul_offset = {10, 24}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {1, 0, 0}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    self.flip = nil

    -- Path to this actor's sprites (defaults to "")
    self.path = ""
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = ""

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Font to use when this actor speaks (optional)
    self.font = nil
    -- Font size to use for the chosen font for speech bubbles in battles (optional)
    -- Recommended to use half of the default size
    self.speech_bubble_font_size = nil
    -- Indent style for the actor (optional)
    self.indent_string = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of talk sprites and their talk speeds (default 0.25)
    self.talk_sprites = {}

    -- Table of sprites that have a unique flip value, if self.flip is not set
    self.flip_sprites = {}

    -- Tables of sprites to change into in mirrors
    self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",
    }

    -- Table of sprite animations
    self.animations = {}

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {}
end

-- Callbacks

function Actor:onWorldUpdate(chara) end
function Actor:onWorldDraw(chara) end

function Actor:onBattleUpdate(battler) end
function Actor:onBattleDraw(battler) end

function Actor:onTalkStart(text, sprite) end
function Actor:onTalkEnd(text, sprite) end

function Actor:onSpriteInit(sprite) end

function Actor:preSet(sprite, name, callback) end
function Actor:onSet(sprite, name, callback) end

function Actor:preSetSprite(sprite, texture, keep_anim) end
function Actor:onSetSprite(sprite, texture, keep_anim) end

function Actor:preSetAnimation(sprite, anim, callback) end
function Actor:onSetAnimation(sprite, anim, callback) end

function Actor:preResetSprite(sprite) end
function Actor:onResetSprite(sprite) end

function Actor:preSpriteUpdate(sprite) end
function Actor:onSpriteUpdate(sprite) end

function Actor:preSpriteDraw(sprite) end
function Actor:onSpriteDraw(sprite) end

-- Getters

function Actor:getName() return self.name or self.id end

function Actor:getWidth() return self.width end
function Actor:getHeight() return self.height end
function Actor:getSize() return self:getWidth(), self:getHeight() end

function Actor:getHitbox()
    if self.hitbox then
        local x, y, w, h = unpack(self.hitbox)
        return x or 0, y or 0, w or self:getWidth(), h or self:getHeight()
    else
        return 0, 0, self:getWidth(), self:getHeight()
    end
end

function Actor:getSoulOffset()
    return unpack(self.soul_offset)
end

function Actor:getColor()
    if self.color then
        return self.color[1], self.color[2], self.color[3], self.color[4] or 1
    else
        return 1, 0, 0, 1
    end
end

function Actor:getSpritePath() return self.path or "" end

function Actor:getDefaultSprite() return self.default_sprite end
function Actor:getDefaultAnim() return self.default_anim end
function Actor:getDefault() return self:getDefaultAnim() or self:getDefaultSprite() or self.default or "" end

function Actor:getVoice() return self.voice end
function Actor:getFont() return self.font end
function Actor:getSpeechBubbleFontSize() return self.speech_bubble_font_size end
function Actor:getIndentString() return self.indent_string end

function Actor:getPortraitPath() return self.portrait_path end
function Actor:getPortraitOffset() return unpack(self.portrait_offset or {0, 0}) end

function Actor:getFlipDirection(sprite) return self.flip or self.flip_sprites[sprite] end

function Actor:hasTalkSprite(sprite) return self.talk_sprites[sprite] ~= nil end
function Actor:getTalkSpeed(sprite) return self.talk_sprites[sprite] or 0.25 end

function Actor:getAnimation(anim) return self.animations[anim] end

function Actor:getMirrorSprites() return self.mirror_sprites end
function Actor:getMirrorSprite(sprite) return self:getMirrorSprites()[sprite] end

function Actor:hasOffset(sprite) return self.offsets[sprite] ~= nil end
function Actor:getOffset(sprite) return unpack(self.offsets[sprite] or {0, 0}) end

-- Misc Functions
function Actor:createSprite()
    return ActorSprite(self)
end

-- horrific
function Actor:parseSpriteOptions(full_sprite, ignore_frames)
    local prefix = self:getSpritePath().."/"
    local is_relative, relative_sprite = Utils.startsWith(full_sprite, prefix)
    if not is_relative and self:getSpritePath() ~= "" then
        return {""}
    end

    local result = {relative_sprite}

    if not ignore_frames then
        local frames_for = Assets.getFramesFor(full_sprite)
        if frames_for then
            local success, frames_sprite = Utils.startsWith(frames_for, prefix)
            if success then
                table.insert(result, frames_sprite)
            end
            full_sprite = frames_for
        end
    end

    local dirs = {"left", "right", "up", "down"}

    for _, dir in ipairs(dirs) do
        local success, dir_sprite = Utils.endsWith(full_sprite, "_"..dir)
        if not success then
            success, dir_sprite = Utils.endsWith(full_sprite, "/"..dir)
        end
        if success then
            local relative, sprite = Utils.startsWith(dir_sprite, prefix)
            if relative then
                table.insert(result, sprite)
            end
        end
    end

    return result
end

return Actor