extern number wave_sine;
extern number wave_mag;
extern number wave_height;
extern vec2 texsize;
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    number i = texture_coords.y * texsize.y;
    vec2 coords = vec2(max(0.0, min(1.0, texture_coords.x + (sin((i / wave_height) + (wave_sine / 30.0)) * wave_mag) / texsize.x)), max(0.0, min(1.0, texture_coords.y + 0.0)));
    return Texel(texture, coords) * color;
}
