local EditorTileButton, super = Class(EditorEvent)

EditorTileButton.sprite_property = "sprite"
function EditorTileButton:getEditorSprite(data)
    return data.properties.sprite or "world/events/glowtile/idle"
end
function EditorTileButton:init(data, options)
    super.init(self, data, options)
    self:registerProperty("sprite", "string")
    self:registerProperty("pressedsprite", "string", { name = "Pressed Sprite" })
    self:registerProperty("onsound", "string", { name = "On Sound" })
    self:registerProperty("offsound", "string", { name = "Off Sound" })
    self:registerProperty("blocks", "boolean")
    self:registerProperty("group", "string")
    self:registerProperty("flag", "string")
    self:registerProperty("once", "boolean")
    self:registerProperty("keepdown", "boolean", { name = "Keep Down" })
    self:registerProperty("cutscene", "string")
    self:registerProperty("script", "string")
end
function EditorTileButton:createObject(map, context)
    return TileButton(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorTileButton
