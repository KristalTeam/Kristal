local Item = Class()

function Item:init(o)
    o = o or {}

    -- Load the table
    for k,v in pairs(o) do
        self[k] = v
    end
end

function Item:onEquip(character)
    
end

function Item:onWorldUse(target)
end

function Item:onBattleUse(target)
end

return Item