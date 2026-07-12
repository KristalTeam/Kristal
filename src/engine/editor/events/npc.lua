local EditorNPC, super = Class(EditorEvent)

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
    self:registerProperty("talk", "boolean", { default = true })
    self:registerProperty("talksprite", "string", { name = "Talk Sprite" })
    self:registerProperty("solid", "boolean", { default = true })
    self:registerProperty("cutscene", "string")
    self:registerProperty("script", "string")
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
    self:registerProperty("path", "string")
    self:registerProperty("speed", "number", { default = 6 })
    self:registerProperty("progress", "number")
end

return EditorNPC
