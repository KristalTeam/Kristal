local Shaders = {}

Shaders["GradientH"] = love.graphics.newShader([[
    extern vec3 from;
    extern vec3 to;
    extern number scale;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 froma = vec4(from.r, from.g, from.b, 1);
        vec4 toa = vec4(to.r, to.g, to.b, 1);
        return Texel(tex, texture_coords) * (froma + (toa - froma) * mod(texture_coords.x / scale, 1)) * color;
    }
]])

Shaders["GradientV"] = love.graphics.newShader([[
    extern vec3 from;
    extern vec3 to;
    extern number scale;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 froma = vec4(from.r, from.g, from.b, 1);
        vec4 toa = vec4(to.r, to.g, to.b, 1);
        return Texel(tex, texture_coords) * (froma + (toa - froma) * mod(texture_coords.y / scale, 1)) * color;
    }
]])

Shaders["GradientH"]:send("scale", 1)
Shaders["GradientV"]:send("scale", 1)

Shaders["DynGradient"] = love.graphics.newShader([[
    uniform Image colors;
    uniform vec2 colorSize;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        float cx = texture_coords.x * (colorSize.x - 1) + 0.5;
        float cy = texture_coords.y * (colorSize.y - 1) + 0.5;

        float from_x = (max(0, floor(cx - 0.5)) + 0.5) / colorSize.x;
        float to_x = from_x + 1.0 / colorSize.x;

        float from_y = (max(0, floor(cy - 1)) + 0.5) / colorSize.y;
        float to_y = from_y + 1.0 / colorSize.y;

        vec4 color_upper = mix(Texel(colors, vec2(from_x, from_y)), Texel(colors, vec2(to_x, from_y)), cx - (from_x * colorSize.x));
        vec4 color_lower = mix(Texel(colors, vec2(from_x, to_y)), Texel(colors, vec2(to_x, to_y)), cx - (from_x * colorSize.x));

        return Texel(tex, texture_coords) * mix(color_upper, color_lower, cy - (from_y * colorSize.y)) * color;
    }
]])

Shaders["White"] = love.graphics.newShader([[
    extern float whiteAmount;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 outputcolor = Texel(tex, texture_coords) * color;
        outputcolor.rgb += (vec3(1, 1, 1) - outputcolor.rgb) * whiteAmount;
        return outputcolor;
    }
]])

Shaders["AddColor"] = love.graphics.newShader([[
    extern vec3 inputcolor;
    extern float amount;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 outputcolor = Texel(tex, texture_coords) * color;
        outputcolor.rgb += (inputcolor.rgb - outputcolor.rgb) * amount;
        return outputcolor;
    }
]])

Shaders["Mask"] = love.graphics.newShader[[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        if (Texel(tex, texture_coords).a == 0) {
            // a discarded pixel wont be applied as the stencil.
            discard;
        }
        return vec4(1.0);
    }
 ]]

return Shaders