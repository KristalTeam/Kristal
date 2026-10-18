---@class EditorNPC : EditorObject
---@overload fun(data?: table, options?: table): EditorNPC
local EditorNPC, super = Class(EditorObject)
EditorNPC.editor_sprite = "editor/npc"
EditorNPC.scaling_mode = "scale"
EditorNPC.fixed_shape = "rectangle"
EditorNPC.getPropertyBounds = EditorObject.getSpriteBounds

function EditorNPC:getEditorSprite(data)
    local properties = data.properties or {}
    if not properties.actor then return nil end
    local success, actor = pcall(Registry.createActor, properties.actor)
    if not success or not actor then return nil end
    local sprite = properties.sprite
    if not sprite and properties.animation then
        local animation = actor:getAnimation(properties.animation)
        sprite = type(animation) == "table" and animation[1] or nil
    end
    if not sprite then
        sprite = actor:getDefaultSprite()
        if not sprite and actor:getDefaultAnim() then
            local animation = actor:getAnimation(actor:getDefaultAnim())
            sprite = type(animation) == "table" and animation[1] or nil
        end
        sprite = sprite or actor.default
    end
    if type(sprite) ~= "string" then return nil end
    local path = actor:getSpritePath()
    if path == "" or sprite == "" then return path .. sprite end
    return path:sub(-1) == "/" and (path .. sprite) or (path .. "/" .. sprite)
end
function EditorNPC:init(data, options)
    super.init(self, data, options)
    self:registerProperty("actor", "chooser", {
        choices = Registry.editor_properties:registryChoices("actors")
    })
    self:registerProperty("sprite", "string")
    self:registerProperty("animation", "string")
    self:registerProperty("facing", "choice", { choices = { "up", "down", "left", "right" }, default = "down" })
    self:registerProperty("turn", "boolean")
    self:registerProperty("text", "table", { name = "Dialogue", array = true })
    self:registerProperty("talk", "boolean", { default = true })
    self:registerProperty("talksprite", "string", { name = "Talk Sprite" })
    self:registerProperty("solid", "boolean", { default = true })
    self:registerProperty("cutscene", "script_path", {
        path_root = "scripts/world/cutscenes", strip_extension = true,
        extensions = { "lua" }, registry = "world_cutscenes"
    })
    self:registerProperty("script", "script_path", {
        path_root = "scripts/world/scripts", strip_extension = true,
        extensions = { "lua" }, registry = "event_scripts"
    })
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
    self:registerProperty("path", "string")
    self:registerProperty("speed", "number", { default = 6 })
    self:registerProperty("progress", "number")
end

function EditorNPC:createObject(map, context)
    local x, y = self:getCharacterPosition(map)
    return NPC(self.data.properties.actor, x, y, self.data.properties)
end

---@param map_data table?
function EditorNPC:convertLegacyBounds(map_data)
    local width, height = self.data.width or 0, self.data.height or 0
    local old_x, old_y = self.data.x or 0, self.data.y or 0
    super.convertLegacyBounds(self, map_data)
    if self.data.gid or self.data.tileset and self.data.tile_id ~= nil then return end
    local new_width, new_height = self:getBounds()
    local x, y = (width - new_width) / 2, height / 2 - new_height
    local success, sprite_x, sprite_y = pcall(function()
        local actor = Registry.createActor(self.properties.actor)
        local sprite = actor:createSprite()
        if self.properties.sprite then
            sprite:setSprite(self.properties.sprite)
        elseif self.properties.animation then
            sprite:setAnimation(self.properties.animation)
        end
        sprite:setFacing(self.properties.facing or "down")
        local center_x, center_y = sprite:getRelativePos(sprite.texture:getWidth() / 2,
            sprite.texture:getHeight() / 2)
        return (center_x - actor:getWidth() / 2) * 2, (center_y - actor:getHeight()) * 2
    end)
    if success then
        x, y = (width - new_width) / 2 + sprite_x, (height - new_height) / 2 + sprite_y
    end
    local offset_x = x * math.cos(self.rotation) - y * math.sin(self.rotation)
    local offset_y = x * math.sin(self.rotation) + y * math.cos(self.rotation)
    self.x = self.x + old_x + offset_x - (self.data.x or 0)
    self.y = self.y + old_y + offset_y - (self.data.y or 0)
    self.data.x, self.data.y = old_x + offset_x, old_y + offset_y
end

return EditorNPC
