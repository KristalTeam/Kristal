local function iter(o)
    local list = o.list

end

local function getLayer(o, v)
    return v.layer
end

local function new()
    local o = {}

    o.list = nil
    o.next_id = 1

    o.iter = iter
end

local function remove()

end