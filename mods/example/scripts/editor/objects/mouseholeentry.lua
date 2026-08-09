local EditorMouseholeEntry = Class(EditorObject)

function EditorMouseholeEntry:createObject(map, context)
    return MouseholeEntry(self.data.x, self.data.y, self:getRectData())
end

return EditorMouseholeEntry
