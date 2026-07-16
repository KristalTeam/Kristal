local ActorPreview, super = Class(EditorControl)

local DIRECTIONS = { "down", "left", "right", "up" }

local function join(first, second)
    if not first or first == "" then return second or "" end
    if not second or second == "" then return first end
    return first:gsub("/+$", "") .. "/" .. second:gsub("^/+", "")
end

local function framesFor(path)
    if not path or path == "" then return nil end
    local texture = Assets.getTexture(path)
    if texture then return { texture }, path end
    local frames = Assets.getFrames(path)
    if frames then return frames, path end
end

local function directionalFrames(path, direction)
    local frames, resolved = framesFor(path)
    if frames then return frames, resolved, false end
    for _, separator in ipairs({ "/", "_" }) do
        frames, resolved = framesFor(path .. separator .. direction)
        if frames then return frames, resolved, true end
    end
end

local function firstTextureUnder(path)
    local prefix = tostring(path or ""):gsub("/+$", "") .. "/"
    local ids = {}
    for id in pairs(Assets.data and Assets.data.texture or {}) do
        if StringUtils.startsWith(id, prefix) then table.insert(ids, id) end
    end
    for id in pairs(Assets.data and Assets.data.frames or {}) do
        if StringUtils.startsWith(id, prefix) then table.insert(ids, id) end
    end
    table.sort(ids)
    local frames = ids[1] and Assets.getFramesOrTexture(ids[1])
    return frames and frames[1]
end

local function previewTexture(path)
    return path and Assets.resolveTextureReference(path) or path and firstTextureUnder(path)
end

local function portraitScale(texture)
    if not texture then return 1 end
    return math.min(4, math.max(1, math.floor(120
        / math.max(texture:getWidth(), texture:getHeight()))))
end

function ActorPreview:init(owner)
    super.init(self, 0, 0, 420, 420)
    self.owner = owner
    self.focusable = true
    self.clip = true
    self.timer = 0
    self.drag = nil
    self.cursor_type = "cross"
end

function ActorPreview:getActorSize()
    local model = self.owner.model
    if not model then return 16, 16 end
    return math.max(1, tonumber(self.owner:getActorField("width")) or 16),
        math.max(1, tonumber(self.owner:getActorField("height")) or 16)
end

function ActorPreview:getScale()
    local width, height = self:getActorSize()
    return math.max(1, math.min(8, math.floor(math.min(
        math.max(1, self.width - 48) / width,
        math.max(1, self.height - 72) / height))))
end

function ActorPreview:getOrigin()
    local actor_width, actor_height = self:getActorSize()
    local scale = self:getScale()
    return math.floor((self.width - actor_width * scale) / 2),
        math.floor((self.height - actor_height * scale) / 2), scale
end

function ActorPreview:resolveAnimation(animation_id, direction)
    local model = self.owner.model
    local animation = model and model.animations[animation_id]
    local sprite = self.owner.DataModel.getAnimationSprite(animation)
    if not sprite then return nil end
    local path = join(self.owner:getActorField("path"), sprite)
    local frames, resolved, directional = directionalFrames(path, direction or self.owner.direction or "down")
    return frames, resolved, directional, animation
end

function ActorPreview:getFrame(frames, animation)
    if not frames or #frames == 0 then return nil end
    local delay = math.max(0.01, self.owner.DataModel.getAnimationDelay(animation) or 0.25)
    return frames[(math.floor(self.timer / delay) % #frames) + 1]
end

function ActorPreview:getDefaultAnimationId()
    local explicit = self.owner:getActorField("default_anim")
    if type(explicit) == "string" and self.owner.model.animations[explicit] then return explicit end
    local default = self.owner:getActorField("default")
    if type(default) == "string" and self.owner.model.animations[default] then return default end
end

function ActorPreview:getOffset(animation_id)
    local key = self.owner:getAnimationOffsetKey(animation_id)
    local animation = self.owner.model and self.owner.model.animations[animation_id]
    local base_key = self.owner.DataModel.getAnimationSprite(animation) or animation_id
    local offset = self.owner.model and (self.owner.model.offsets[key] or self.owner.model.offsets[base_key])
    return tonumber(offset and offset[1]) or 0, tonumber(offset and offset[2]) or 0
end

function ActorPreview:drawAnimation(animation_id, alpha, reference)
    if not animation_id then return false end
    local frames, _, _, animation = self:resolveAnimation(animation_id, self.owner.direction)
    local texture = self:getFrame(frames, animation)
    if not texture then return false end
    local origin_x, origin_y, scale = self:getOrigin()
    local offset_x, offset_y = self:getOffset(animation_id)
    if reference then
        Draw.setColor(0.55, 0.75, 1, alpha)
    else
        Draw.setColor(1, 1, 1, alpha)
    end
    Draw.draw(texture, origin_x + offset_x * scale, origin_y + offset_y * scale,
        0, scale, scale)
    return true
end

function ActorPreview:drawRawAnimation(animation, alpha, reference)
    local sprite = self.owner.DataModel.getAnimationSprite(animation)
    if not sprite then return false end
    local frames = directionalFrames(join(self.owner:getActorField("path"), sprite),
        self.owner.direction or "down")
    local texture = self:getFrame(frames, animation)
    if not texture then return false end
    local origin_x, origin_y, scale = self:getOrigin()
    local offset = self.owner.model.offsets[sprite] or { 0, 0 }
    Draw.setColor(reference and { 0.55, 0.75, 1, alpha } or { 1, 1, 1, alpha })
    Draw.draw(texture, origin_x + (tonumber(offset[1]) or 0) * scale,
        origin_y + (tonumber(offset[2]) or 0) * scale, 0, scale, scale)
    return true
end

function ActorPreview:drawDefault(alpha, reference)
    local default_anim = self.owner:getActorField("default_anim")
    if type(default_anim) == "string" and self.owner.model.animations[default_anim] then
        return self:drawAnimation(default_anim, alpha, reference), default_anim
    elseif default_anim and self:drawRawAnimation(default_anim, alpha, reference) then
        return true
    end
    local default_sprite = self.owner:getActorField("default_sprite")
        or self.owner:getActorField("default")
    if type(default_sprite) == "string" and self.owner.model.animations[default_sprite] then
        return self:drawAnimation(default_sprite, alpha, reference), default_sprite
    end
    return self:drawRawAnimation(default_sprite, alpha, reference)
end

function ActorPreview:drawActorBounds()
    local actor_width, actor_height = self:getActorSize()
    local origin_x, origin_y, scale = self:getOrigin()
    Draw.setColor(0.35, 0.75, 1, 0.85)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", origin_x + 0.5, origin_y + 0.5,
        actor_width * scale - 1, actor_height * scale - 1)
end

function ActorPreview:drawHitbox()
    local hitbox = self.owner:getActorField("hitbox")
    local actor_width, actor_height = self:getActorSize()
    if type(hitbox) ~= "table" then hitbox = { 0, 0, actor_width, actor_height } end
    local origin_x, origin_y, scale = self:getOrigin()
    local x, y = origin_x + (tonumber(hitbox[1]) or 0) * scale,
        origin_y + (tonumber(hitbox[2]) or 0) * scale
    local width, height = math.max(0, tonumber(hitbox[3]) or actor_width) * scale,
        math.max(0, tonumber(hitbox[4]) or actor_height) * scale
    Draw.setColor(1, 0.35, 0.25, 0.18)
    love.graphics.rectangle("fill", x, y, width, height)
    Draw.setColor(1, 0.35, 0.25, 0.95)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1)
    love.graphics.rectangle("fill", x + width - 4, y + height - 4, 8, 8)
end

function ActorPreview:drawSoul()
    local offset = self.owner:getActorField("soul_offset") or { 0, 0 }
    local origin_x, origin_y, scale = self:getOrigin()
    local x = origin_x + (tonumber(offset[1]) or 0) * scale
    local y = origin_y + (tonumber(offset[2]) or 0) * scale
    local color = self.owner:getActorField("color") or { 1, 0, 0, 1 }
    Draw.setColor(color)
    local size = math.max(4, math.min(10, scale * 2))
    love.graphics.polygon("fill",
        x, y + size,
        x - size, y,
        x - size * 0.55, y - size * 0.65,
        x, y - size * 0.2,
        x + size * 0.55, y - size * 0.65,
        x + size, y)
    Draw.setColor(1, 1, 1, 0.8)
    love.graphics.line(x - size - 3, y, x + size + 3, y)
    love.graphics.line(x, y - size - 3, x, y + size + 3)
end

function ActorPreview:drawPortraits()
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    local half = math.floor(self.width / 2)
    local center_y = math.floor(self.height / 2)
    local targets = {
        {
            key = "portrait", label = "Portrait", path = self.owner:getActorField("portrait_path"),
            offset = self.owner:getActorField("portrait_offset") or { 0, 0 },
            x = math.floor(half / 2), y = center_y
        },
        {
            key = "miniface", label = "Miniface", path = self.owner:getActorField("miniface"),
            offset = self.owner:getActorField("miniface_offset") or { 0, 0 },
            x = half + math.floor(half / 2), y = center_y
        }
    }
    for _, target in ipairs(targets) do
        Draw.setColor(0.24, 0.24, 0.28, 1)
        love.graphics.rectangle("line", target.x - 70.5, target.y - 70.5, 141, 141)
        local texture = previewTexture(target.path)
        if texture then
            local scale = portraitScale(texture)
            Draw.setColor(1, 1, 1, 1)
            Draw.draw(texture,
                target.x + (tonumber(target.offset[1]) or 0) * scale,
                target.y + (tonumber(target.offset[2]) or 0) * scale,
                0, scale, scale, texture:getWidth() / 2, texture:getHeight() / 2)
        end
        Draw.setColor(self.owner.portrait_target == target.key
            and { 0.55, 0.78, 1, 1 } or { 0.70, 0.70, 0.74, 1 })
        love.graphics.printf(target.label, target.x - 70, target.y + 78, 140, "center")
    end
end

function ActorPreview:update(dt)
    self.timer = self.timer + dt
    super.update(self, dt)
end

function ActorPreview:drawSelf()
    love.graphics.push("all")
    Draw.setColor(0.055, 0.055, 0.065, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.13, 0.13, 0.16, 1)
    for x = 0, self.width, 16 do love.graphics.line(x, 0, x, self.height) end
    for y = 0, self.height, 16 do love.graphics.line(0, y, self.width, y) end

    if not self.owner.model then
        local font = EditorFont.get(16)
        love.graphics.setFont(font)
        Draw.setColor(0.55, 0.55, 0.60, 1)
        love.graphics.printf("Select an actor to preview it.", 12, self.height / 2 - 10,
            math.max(0, self.width - 24), "center")
        love.graphics.pop()
        return
    end

    if self.owner.mode == "portraits" then
        self:drawPortraits()
    else
        if self.owner.mode == "animation" then
            local selected = self.owner.selected_animation
            local default = self:getDefaultAnimationId()
            if self.owner.show_reference and default ~= selected then self:drawDefault(0.28, true) end
            if not self:drawAnimation(selected, 1, false) then self:drawDefault(1, false) end
        else
            self:drawDefault(1, false)
        end
        self:drawActorBounds()
        if self.owner.mode == "hitbox" then self:drawHitbox() end
        if self.owner.mode == "soul" then self:drawSoul() end
    end

    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    local hints = {
        animation = "Drag the preview to adjust this direction's offset",
        hitbox = "Drag to move; drag the bottom-right handle to resize",
        portraits = "Drag either preview to adjust its dialogue offset",
        soul = "Drag the soul marker to adjust its offset"
    }
    Draw.setColor(0.70, 0.74, 0.80, 0.9)
    love.graphics.printf(hints[self.owner.mode] or "", 8, 7, math.max(0, self.width - 16), "center")
    Draw.setColor(0.72, 0.72, 0.76, 1)
    love.graphics.print(string.format("%d%%", self:getScale() * 100), 8, self.height - font:getHeight() - 7)
    love.graphics.pop()
end

function ActorPreview:onMousePressed(x, y, button)
    if button ~= 1 or not self.owner.model then return false end
    local origin_x, origin_y, scale = self:getOrigin()
    if self.owner.mode == "animation" and self.owner.selected_animation then
        local ox, oy = self:getOffset(self.owner.selected_animation)
        self.drag = { kind = "offset", start_x = x, start_y = y, x = ox, y = oy }
        self.owner:beginContinuousEdit("Move Animation Offset")
    elseif self.owner.mode == "hitbox" then
        local hitbox = self.owner:getActorField("hitbox")
        local actor_width, actor_height = self:getActorSize()
        hitbox = type(hitbox) == "table" and hitbox or { 0, 0, actor_width, actor_height }
        local hx = origin_x + (tonumber(hitbox[1]) or 0) * scale
        local hy = origin_y + (tonumber(hitbox[2]) or 0) * scale
        local hw = (tonumber(hitbox[3]) or actor_width) * scale
        local hh = (tonumber(hitbox[4]) or actor_height) * scale
        local resize = math.abs(x - (hx + hw)) <= 10 and math.abs(y - (hy + hh)) <= 10
        self.drag = {
            kind = resize and "hitbox_resize" or "hitbox_move",
            start_x = x, start_y = y, value = self.owner.DataModel.copy(hitbox)
        }
        self.owner:beginContinuousEdit(resize and "Resize Hitbox" or "Move Hitbox")
    elseif self.owner.mode == "soul" then
        self.drag = { kind = "soul", start_x = x, start_y = y,
            value = self.owner.DataModel.copy(self.owner:getActorField("soul_offset") or { 0, 0 }) }
        self.owner:beginContinuousEdit("Move Soul Offset")
    elseif self.owner.mode == "portraits" then
        local target = x < self.width / 2 and "portrait" or "miniface"
        self.owner:setPortraitTarget(target)
        local key = target == "portrait" and "portrait_offset" or "miniface_offset"
        local path_key = target == "portrait" and "portrait_path" or "miniface"
        local drag_scale = portraitScale(previewTexture(self.owner:getActorField(path_key)))
        self.drag = { kind = "portrait", key = key, start_x = x, start_y = y,
            scale = drag_scale,
            value = self.owner.DataModel.copy(self.owner:getActorField(key) or { 0, 0 }) }
        self.owner:beginContinuousEdit("Move " .. (target == "portrait" and "Portrait" or "Miniface") .. " Offset")
    end
    return self.drag ~= nil
end

function ActorPreview:onMouseMoved(x, y)
    if not self.drag then return false end
    local scale = self.drag.scale or self:getScale()
    local dx, dy = MathUtils.round((x - self.drag.start_x) / scale),
        MathUtils.round((y - self.drag.start_y) / scale)
    if self.drag.kind == "offset" then
        self.owner:setAnimationOffset(self.drag.x + dx, self.drag.y + dy, true)
    elseif self.drag.kind == "hitbox_move" then
        local value = self.owner.DataModel.copy(self.drag.value)
        value[1], value[2] = (tonumber(value[1]) or 0) + dx, (tonumber(value[2]) or 0) + dy
        self.owner:setActorField("hitbox", value, true)
    elseif self.drag.kind == "hitbox_resize" then
        local value = self.owner.DataModel.copy(self.drag.value)
        value[3], value[4] = math.max(0, (tonumber(value[3]) or 0) + dx),
            math.max(0, (tonumber(value[4]) or 0) + dy)
        self.owner:setActorField("hitbox", value, true)
    elseif self.drag.kind == "soul" or self.drag.kind == "portrait" then
        local value = self.owner.DataModel.copy(self.drag.value)
        value[1], value[2] = (tonumber(value[1]) or 0) + dx, (tonumber(value[2]) or 0) + dy
        self.owner:setActorField(self.drag.kind == "soul" and "soul_offset" or self.drag.key, value, true)
    end
    return true
end

function ActorPreview:onMouseReleased(_, _, button)
    if button ~= 1 or not self.drag then return false end
    self.drag = nil
    self.owner:finishContinuousEdit()
    return true
end

function ActorPreview:getDirections()
    local animation_id = self.owner.selected_animation or self:getDefaultAnimationId()
    local animation = animation_id and self.owner.model.animations[animation_id]
    local sprite = self.owner.DataModel.getAnimationSprite(animation)
    if not sprite then return {} end
    local base = join(self.owner:getActorField("path"), sprite)
    local directions = {}
    for _, direction in ipairs(DIRECTIONS) do
        if framesFor(base .. "/" .. direction) or framesFor(base .. "_" .. direction) then
            table.insert(directions, direction)
        end
    end
    return directions
end

return ActorPreview
