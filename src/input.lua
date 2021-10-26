local Input = {}
local self = Input

-- TODO: rebinding

function Input.isConfirm(key)
    return (key == "z") or (key == "return")
end

function Input.isCancel(key)
    return (key == "x") or (key == "lshift") or (key == "rshift")
end

function Input.isMenu(key)
    return (key == "c") or (key == "lctrl") or (key == "rctrl")
end

function Input.Confirm()
    return love.keyboard.isDown("z") or love.keyboard.isDown("return")
end

function Input.Cancel()
    return love.keyboard.isDown("x") or love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function Input.Menu()
    return love.keyboard.isDown("c") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

return Input