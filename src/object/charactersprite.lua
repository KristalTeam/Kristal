local CharacterSprite, super = Class(Sprite)

function CharacterSprite:init(chara)
    self.info = chara
    self.path = chara.path or ""
    self.sprite = nil
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

function CharacterSprite:setSprite(texture)
    if type(texture) ~= "string" then
        error("Texture must be a string")
    end

    self.sprite = texture
    self.directional, self.dir_sep = self:isDirectional(texture)

    if self.directional then
        self.loop = true
        super:setSprite(self, self:getPath(texture)..self.dir_sep..self.facing)
    else
        self.walk_frame = 1
        super:setSprite(self, self:getPath(texture))
    end
end

function CharacterSprite:updateDirection()
    if self.directional and self.last_facing ~= self.facing then
        super:setSprite(self, self:getPath(self.sprite)..self.dir_sep..self.facing)
    end
    self.last_facing = self.facing
end

function CharacterSprite:isDirectional(texture)
    local path = self:getPath(texture)
    if Assets.getTexture(path.."_left") or Assets.getFrames(path.."_left") then
        return true, "_"
    elseif Assets.getTexture(path.."/left") or Assets.getFrames(path.."/left") then
        return true, "/"
    end
end

function CharacterSprite:getOffset()
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