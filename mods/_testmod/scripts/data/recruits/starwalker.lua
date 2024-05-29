-- This is just a test, use the virovirokun.lua as a base instead
local Starwalker, super = Class(Recruit)

function Starwalker:init()
    super.init(self)
    
    -- Display Name
    self.name = "Starwalker"
    
    -- How many times an enemy needs to be spared to be recruited
    self.recruit_amount = 1
    
    -- Organize the order that recruits show up in the recruit menu
    self.index = 2
    
    -- Selection Display
    self.description = "The original        Starwalker"
    self.chapter = 1
    self.level = 99
    self.attack = 1
    self.defense = 1
    self.element = "STAR"
    self.like = "Original"
    self.dislike = "Unoriginal"
    
    -- Controls the type of the box gradient
    -- Available options: dark, bright
    self.box_gradient_type = "dark"
    
    -- Dyes the box gradient
    self.box_gradient_color = {1,0,1,1}
    
    -- Sets the animated sprite in the box
    -- Syntax: Sprite/Animation path, offset_x, offset_y, animation_speed
    self.box_sprite = {"npcs/starwalker/starwalker", 4, 12, 4/30}
    
    -- Recruit Status (saved to the save file)
    -- Number: Recruit Progress
    -- Boolean: True = Recruited | False = Lost Forever
    self.recruited = true
    
    -- Whether the recruit will be hidden from the recruit menu (saved to the save file)
    self.hidden = false
end

return Starwalker