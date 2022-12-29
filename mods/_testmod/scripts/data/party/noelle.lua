local character, super = Class("noelle", true)

function character:init()
    super.init(self)

    self:addSpell("snowgrave")
end

return character