--- Creates a region in the Overworld that reflects characters inside it. \
--- `MirrorArea` is an [`Event`](lua://Event.init) - naming an object `mirror` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object. \
--- To customise how mirror sprites are displayed, refer to [`Actor`](lua://Actor.init)s and their [`mirror_sprites`](lua://Actor.mirror_sprites) table and functions: [`getMirrorSprites`](lua://Actor.getMirrorSprites), [`getMirrorSprite`](lua://Actor.getMirrorSprite)
---@class MirrorArea : Event
---
---@field offset    number  *[Property `offset`]* The y-offset for reflections drawn in this mirror (Defaults to `0`)
---@field opacity   number  *[Property `opacity`]* The opacity of reflections drawn in the mirror (Defaults to `1`)
---
---@field bottom    number
---
---@overload fun(...) : MirrorArea
local MirrorArea, super = Class(Event)

function MirrorArea:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.offset = properties["offset"] or 0
    self.opacity = properties["opacity"] or 1

    self.bottom = self.y + self.height
end

--- Finds and draws all character's reflections
function MirrorArea:drawMirror()
    local to_draw = {}
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(Character) and obj.visible then
            table.insert(to_draw, 1, obj) -- always add to the start of the table, so they render in reverse layer order
        end
    end
    for _, obj in ipairs(to_draw) do
        self:drawCharacter(obj)
    end
end

--- Draws a character's reflection
---@param chara Character
function MirrorArea:drawCharacter(chara)
    local tex_path = chara.sprite.texture_path
    local tex_name, frame = Assets.getFramesFor(tex_path)
    if not tex_name then tex_name, frame = tex_path, 1 end
    local old_tex_obj ---@type love.Image?

    local actor_spr_path = chara.actor:getSpritePath() or ""
    if actor_spr_path ~= "" then actor_spr_path = actor_spr_path .. "/" end
    local tex_in_actor_spr_path, tex_name_rel = StringUtils.startsWith(tex_name, actor_spr_path)
    if tex_in_actor_spr_path then
        local mirror_sprites = chara.actor:getMirrorSprites()
        if mirror_sprites and mirror_sprites[tex_name_rel] then
            local new_frames = Assets.getFramesOrTexture(actor_spr_path .. mirror_sprites[tex_name_rel]) or {}
            if #new_frames > 0 then
                local old_frame_count = #(Assets.getFramesOrTexture(tex_name) or {})
                local progress = old_frame_count <= 1 and 0 or ((frame - 1) / (old_frame_count - 1))
                old_tex_obj = chara.sprite.texture
                chara.sprite:setTextureExact(new_frames[1 + math.floor((#new_frames - 1) * progress)])
            end
        end
    end

    -- See Object.drawSelf
    love.graphics.push()
    chara:preDraw()

    -- Unscale
    love.graphics.scale(1 / chara.scale_x, 1 / chara.scale_y)
    -- Go back to the origin
    love.graphics.translate(0, -chara.y)

    -- Start drawing at the bottom of the mirror area...
    local y_offset = (self.bottom + self.offset)
    love.graphics.translate(0, y_offset)

    -- ...and flip the character's position relative to that area
    love.graphics.translate(0, y_offset - chara.y)

    -- Re-scale
    love.graphics.scale(chara.scale_x, chara.scale_y)

    if chara.draw_children_below then
        chara:drawChildren(nil, chara.draw_children_below)
    end
    chara:draw()
    if chara.draw_children_above then
        chara:drawChildren(chara.draw_children_above)
    end
    chara:postDraw()
    love.graphics.pop()

    if old_tex_obj then chara.sprite:setTextureExact(old_tex_obj) end
end

function MirrorArea:draw()
    super.draw(self)

    local canvas = Draw.pushCanvas(self.width, self.height)
    love.graphics.clear()
    love.graphics.translate(-self.x, -self.y)
    self:drawMirror()
    Draw.popCanvas()

    Draw.setColor(1, 1, 1, self.opacity)
    Draw.draw(canvas)
    Draw.setColor(1, 1, 1, 1)
end

return MirrorArea
