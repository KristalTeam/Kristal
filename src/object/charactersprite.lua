local CharacterSprite, super = Class(Sprite)

function CharacterSprite:init(chara)
    self.info = chara
    self.path = chara.path or ""
    self.sprite = nil
    self.full_sprite = nil
    self.facing = "down"
    self.last_facing = "down"

    self.directional = false
    self.dir_sep = "_"

    super:init(self, chara.default or "", 0, 0, chara.width, chara.height)

    self.offsets = chara.offsets or {}

    self.walking = false
    self.walk_speed = 4
    self.walk_frame = 1
end

function CharacterSprite:getPath(name)
    if self.path ~= "" and name ~= "" then
        return self.path.."/"..name
    else
        return self.path..name
    end
end

function CharacterSprite:setCustomSprite(texture, ox, oy)
    if type(texture) ~= "string" then
        error("Texture must be a string")
    end

    self.force_offset = {ox or 0, oy or 0}

    self.full_sprite = texture
    self.directional, self.dir_sep = self:isDirectional(self.full_sprite)

    if self.directional then
        self.loop = true
        super:setSprite(self, self.full_sprite..self.dir_sep..self.facing)
    else
        self.walk_frame = 1
        super:setSprite(self, self.full_sprite)
    end
end

function CharacterSprite:setSprite(texture, ox, oy)
    if type(texture) ~= "string" then
        error("Texture must be a string")
    end

    if ox and oy then
        self.force_offset = {ox, oy}
    else
        self.force_offset = nil
    end

    self.sprite = texture
    self.full_sprite = self:getPath(texture)
    self.directional, self.dir_sep = self:isDirectional(self.full_sprite)

    if self.directional then
        self.loop = true
        super:setSprite(self, self.full_sprite..self.dir_sep..self.facing)
    else
        self.walk_frame = 1
        super:setSprite(self, self.full_sprite)
    end
end

function CharacterSprite:updateDirection()
    if self.directional and self.last_facing ~= self.facing then
        super:setSprite(self, self.full_sprite..self.dir_sep..self.facing)
    end
    self.last_facing = self.facing
end

function CharacterSprite:isDirectional(texture)
    if Assets.getTexture(texture.."_left") or Assets.getFrames(texture.."_left") then
        return true, "_"
    elseif Assets.getTexture(texture.."/left") or Assets.getFrames(texture.."/left") then
        return true, "/"
    end
end

function CharacterSprite:getOffset()
    if self.force_offset then
        return self.force_offset
    end
    local frames_for = Assets.getFramesFor(self.sprite)
    local frames_for_dir = self.directional and Assets.getFramesFor(self.sprite..self.dir_sep..self.facing)
    return self.offsets[self.sprite] or (frames_for and self.offsets[frames_for]) or
            (self.directional and (self.offsets[self.sprite..self.dir_sep..self.facing] or (frames_for_dir and self.offsets[frames_for_dir])))
            or {0, 0}
end

function CharacterSprite:update(dt)
    local floored_frame = math.floor(self.walk_frame)
    if floored_frame ~= self.walk_frame or (self.directional and self.walking) then
        self.walk_frame = Utils.approach(self.walk_frame, floored_frame + 1, dt * (self.walk_speed > 0 and self.walk_speed or 1))
        self:setFrame(floored_frame)
    elseif self.directional and self.frames and not self.walking and not self.playing then
        self:setFrame(1)
    end

    self:updateDirection()

    super:update(self, dt)
end

function CharacterSprite:getTransform()
    local transform = super:getTransform(self)
    local offset = self:getOffset()
    transform:translate(-offset[1], -offset[2])
    return transform
end

return CharacterSprite