---@class Recruit : Class
---@overload fun(...) : Recruit
local Recruit = Class()

function Recruit:init()
    -- Display Name
    self.name = "Test Recruit"
    
    -- How many times an enemy needs to be spared to be recruited.
    self.recruit_amount = 1
    
    -- Selection Display
    self.description = "No description"
    self.chapter = 0
    self.level = 0
    self.attack = 0
    self.defense = 0
    self.element = "UNSET"
    self.like = "Undefined"
    self.dislike = "Undefined"
    
    -- Controls the type of the box gradient
    -- Available options: dark, bright
    self.box_gradient_type = "bright"
    
    -- Dyes the box gradient
    self.box_gradient_color = {1,1,1,1}
    
    -- Sets the animated sprite in the box
    -- Syntax: Sprite/Animation path, offset_x, offset_y
    self.box_sprite = {nil, 0, 0}
    
    -- Recruit Status (saved to the save file)
    -- Number: Recruit Progress
    -- Boolean: True = Recruited | False = Lost Forever
    self.recruited = 0
end

function Recruit:save()
    local data = {
        id = self.id,
        recruited = self.recruited
    }
    self:onSave(data)
    return data
end

function Recruit:load(data)
    self.recruited = data.recruited or self.recruited

    self:onLoad(data)
end

function Recruit:getName() return self.name end
function Recruit:getDescription() return self.description end
function Recruit:getChapter() return self.chapter end
function Recruit:getLevel() return self.level end
function Recruit:getAttack() return self.attack end
function Recruit:getDefense() return self.defense end
function Recruit:getElement() return self.element end
function Recruit:getLike() return self.like end
function Recruit:getDislike() return self.dislike end

function Recruit:getBoxGradientType() return self.box_gradient_type end
function Recruit:getBoxGradientColor() return self.box_gradient_color end
function Recruit:getBoxSprite() return self.box_sprite end

function Recruit:getRecruitAmount() return self.recruit_amount end
function Recruit:getRecruited() return self.recruited end
function Recruit:setRecruited(v) self.recruited = v end

function Recruit:onSave(data) end
function Recruit:onLoad(data) end

return Recruit

