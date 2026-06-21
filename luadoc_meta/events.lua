---@alias EventPolygonPoint {x: number, y: number}
---@alias EventShape [number, number, EventPolygonPoint[]?]

--- A reference to a Tiled object.
---@alias TiledObjectRef {id: integer}

--- A reference to an object in Tiled. Can be its Tiled ID, its name, or a reference to a Tiled object.
---@alias KristalObjectRef string|integer|TiledObjectRef

--- A marker, or a reference to one. Can be its name, its ID, a reference to a Tiled object, the marker data itself, or a position table.
---@alias MarkerRef KristalObjectRef|Marker|Position

--- A simple position table, containing two numbers (X, Y).
---@alias Position [number, number]
