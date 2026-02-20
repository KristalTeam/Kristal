---@class ColorUtils
local ColorUtils = {}

---
--- Converts HSL values to RGB values. Both HSL and RGB should be values between 0 and 1.
---
---@param hue number  # The hue value of the HSL color.
---@param saturation number  # The saturation value of the HSL color.
---@param lightness number  # The lightness value of the HSL color.
---@return number r # The red value of the converted color.
---@return number g # The green value of the converted color.
---@return number b # The blue value of the converted color.
---
--- *Source*: https://github.com/Wavalab/rgb-hsl-rgb
---
function ColorUtils.HSLToRGB(hue, saturation, lightness)
    if saturation == 0 then
        return lightness, lightness, lightness
    end

    local function to(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < .16667 then return p + (q - p) * 6 * t end
        if t < .5 then return q end
        if t < .66667 then return p + (q - p) * (.66667 - t) * 6 end
        return p
    end

    local q = lightness < .5 and lightness * (1 + saturation) or lightness + saturation - lightness * saturation
    local p = 2 * lightness - q
    return to(p, q, hue + .33334), to(p, q, hue), to(p, q, hue - .33334)
end

---
--- Converts RGB values to HSL values. Both RGB and HSL should be values between 0 and 1.
---
---@param red number         # The red value of the RGB color.
---@param green number       # The green value of the RGB color.
---@param blue number        # The blue value of the RGB color.
---@return number hue        # The hue value of the converted color.
---@return number saturation # The saturation value of the converted color.
---@return number lightness  # The lightness value of the converted color.
---
--- *Source*: https://github.com/Wavalab/rgb-hsl-rgb
---
function ColorUtils.RGBToHSL(red, green, blue)
    local max = math.max(red, green, blue)
    local min = math.min(red, green, blue)

    local b = max + min
    local hue = b / 2
    if max == min then return 0, 0, hue end
    local saturation, lightness = hue, hue
    local d = max - min
    saturation = lightness > .5 and d / (2 - b) or d / b
    if max == red then
        hue = (green - b) / d + (green < b and 6 or 0)
    elseif max == green then
        hue = (b - red) / d + 2
    elseif max == b then
        hue = (red - green) / d + 4
    end
    return hue * .16667, saturation, lightness
end

---
--- Converts HSV values to RGB values. Both HSV and RGB should be values between 0 and 1.
---
---@param hue number  # The hue value of the HSV color.
---@param saturation number  # The saturation value of the HSV color.
---@param value number  # The 'value' value of the HSV color.
---@return number r # The red value of the converted color.
---@return number g # The green value of the converted color.
---@return number b # The blue value of the converted color.
---
--- *Source*: https://love2d.org/wiki/HSV_color
---
function ColorUtils.HSVToRGB(hue, saturation, value)
    if saturation <= 0 then
        return value, value, value
    end

    hue = hue * 6
    local chroma = value * saturation
    local second_largest = (1 - math.abs((hue % 2) - 1)) * chroma
    local minimum_component_offset = (value - chroma)
    local red = 0.0
    local green = 0.0
    local blue = 0.0

    if hue < 1 then
        red = chroma
        green = second_largest
        blue = 0
    elseif hue < 2 then
        red = second_largest
        green = chroma
        blue = 0
    elseif hue < 3 then
        red = 0
        green = chroma
        blue = second_largest
    elseif hue < 4 then
        red = 0
        green = second_largest
        blue = chroma
    elseif hue < 5 then
        red = second_largest
        green = 0
        blue = chroma
    else
        red = chroma
        green = 0
        blue = second_largest
    end

    return red + minimum_component_offset,
        green + minimum_component_offset,
        blue + minimum_component_offset
end

---
--- Converts RGB values to HSV values. Both RGB and HSV should be values between 0 and 1.
---
---@param red number         # The red value of the RGB color.
---@param green number       # The green value of the RGB color.
---@param blue number        # The blue value of the RGB color.
---@return number hue        # The hue value of the converted color.
---@return number saturation # The saturation value of the converted color.
---@return number value      # The 'value' value of the converted color.
--- *Source*: https://github.com/iskolbin/lhsx/blob/master/hsx.lua
function ColorUtils.RGBToHSV(red, green, blue)
    local max = math.max(red, green, blue)
    local min = math.min(red, green, blue)
    local chroma = max - min
    local hue_scale = 1 / (6 * chroma)
    local hue = 0.0

    if chroma ~= 0 then
        if max == red then
            hue = ((green - blue) * hue_scale) % 1
        elseif max == green then
            hue = (blue - red) * hue_scale + 1 / 3
        else
            hue = (red - green) * hue_scale + 2 / 3
        end
    end

    return hue, max == 0 and 0 or chroma / max, max
end

local function sizedHexToValueTable(hex_string, component_count)
    local component_size = math.floor((#hex_string / component_count))
    local max_value = tonumber(string.rep("F", component_size), 16)

    if max_value == nil then
        error("Invalid hex color: got " .. hex_string)
    end

    local value_table = {}
    for i = 1, component_count do
        local start = ((i - 1) * component_size) + 1
        local val = tonumber(string.sub(hex_string, start, start + component_size - 1), 16)
        if (val == nil) then
            return nil
        end
        table.insert(value_table, val / max_value)
    end

    return value_table
end

---
--- Converts a hex color string to an RGBA color table.
---
---@param color string   # The hex string to convert to RGBA.
---@return number[] rgba # The converted RGBA table.
---
function ColorUtils.hexToRGB(color)
    local hex_string = color

    -- If it starts with a #, strip it
    if (color:sub(1, 1) == "#") then
        hex_string = color:sub(2)
    end

    -- If our string is larger than 12 (RRRGGGBBBAAA), let's just say it's invalid
    if (#hex_string > 12) then
        error("Invalid hex color: got " .. color)
    end

    -- Is it 4 components? (RGBA, RRGGBBAA, RRRGGGBBBAAA)
    if (MathUtils.isInteger(#hex_string / 4)) then
        local tbl = sizedHexToValueTable(hex_string, 4)
        if (not tbl) then
            error("Invalid hex color: got " .. color)
        end
        return { tbl[1], tbl[2], tbl[3], tbl[4] }
    end

    -- Must be thee components? (RGB, RRGGBB, RRRGGGBBB)
    if (MathUtils.isInteger(#hex_string / 3)) then
        local tbl = sizedHexToValueTable(hex_string, 3)
        if (not tbl) then
            error("Invalid hex color: got " .. color)
        end
        return { tbl[1], tbl[2], tbl[3], 1 }
    end

    error("Invalid hex color: got " .. color)
end

---
--- Converts a color to a hex color string.
---
---@param red number   # The red value of the color, between 0 and 1.
---@param blue number  # The blue value of the color, between 0 and 1.
---@param green number # The green value of the color, between 0 and 1.
---@return string hex  # The converted hex string. Formatted with a # at the start, eg. "#ff00ff".
---
function ColorUtils.RGBToHex(red, blue, green)
    return string.format("#%02X%02X%02X", red * 255, blue * 255, green * 255)
end

---
--- Merges two colors based on a percentage between 0 and 1.
---
---@param start_color number[]   # The first color to merge.
---@param end_color number[]     # The second color to merge.
---@param amount number          # A percentage (from 0 to 1) that determines how much of the second color to merge into the first.
---@return number[] result_color # The two colors, merged together.
---
function ColorUtils.mergeColor(start_color, end_color, amount)
    return TableUtils.lerp(ColorUtils.ensureAlpha(start_color), ColorUtils.ensureAlpha(end_color), amount)
end

---
--- Ensures a color has an alpha value. If the color already has an alpha value, it is returned unchanged.
--- If it does not have an alpha value, an alpha value of 1 is added.
---
---@param color number[]   # The color to ensure has an alpha value.
---@return number[] rgba   # The color, with an alpha value.
function ColorUtils.ensureAlpha(color)
    return { color[1], color[2], color[3], color[4] or 1 }
end

return ColorUtils
