local ModMenu = {}

function ModMenu:enter()
    print("i am so gay")
end

function ModMenu:draw()
    love.graphics.scale(2)
    love.graphics.draw(Assets:getTexture("kristal/title_bg_full"), 0, -20)
end

return ModMenu