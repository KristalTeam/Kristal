
---@clASS SUSI RULES CRISTAL DROOLS
local Text, super = Utils.hookScript(Text)

function Text:getCharPosition(node, state)
    local x, y = super.getCharPosition(self, node, state)
    if state.some_jevil_bullshit then
        x = state.offset_x + (math.sin((state.typed_characters/10) + (Kristal.getTime() * 2))+1) * 300 * 0.5
    end
    return x, y
end

return Text
