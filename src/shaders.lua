local Shaders = {}

Shaders["GradientH"] = love.graphics.newShader([[
    extern vec4 from;
    extern vec4 to;
    extern number scale;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        return Texel(texture, texture_coords) * (from + (to - from) * mod(texture_coords.x / scale, 1)) * color;
    }
]])

Shaders["GradientV"] = love.graphics.newShader([[
    extern vec4 from;
    extern vec4 to;
    extern number scale;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        return Texel(texture, texture_coords) * (from + (to - from) * mod(texture_coords.y / scale, 1)) * color;
    }
]])

Shaders["GradientH"]:send("scale", 1)
Shaders["GradientV"]:send("scale", 1)

return Shaders