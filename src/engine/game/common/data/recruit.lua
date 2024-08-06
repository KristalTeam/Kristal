--- Recruits are data files that define the properties of recruitable enemies. \
--- Recruits are stored in `scripts/data/recruits`, and extend this class. Their filepath starting from here becomes their id, unless an id is specified as an argument to `Class()`. \
--- A recruit is linked to one enemy with the same id as it. 
---
---@class Recruit : Class
---
---@field name              string          The display name of this recruit
---
---@field recruit_amount    integer         How many times this enemy must be spared to recruit it
---
---@field index             integer         This recruit's position in the recruit menu
---
---@field description       string          The description of this recruit, shown on its details page
---@field chapter           string|integer  The chapter number this recruit will be listed as being from, shown on its details page
---@field level             string|integer  The level of this recruit, shown on its details page
---@field attack            string|integer  The attack of this recruit, shown on its details page
---@field defense           string|integer  The defense of this recruit, shown on its details page
---@field element           string          The element of this recruit, shown on its details page
---@field like              string          The dislike of this recruit, shown on its details page
---@field dislike           string          The like of this recruit, shown on its details page
---
---@field box_gradient_type     "bright"|"dark" The type of box gradient the recruit uses, either `"bright"` or `"dark"`
---@field box_gradient_color    table           The color used for drawing the box gradient
---
--- Controls the recruit sprite shown in the recruit menu box \
--- *Usage: Sprite path, x-offset, y-offset, animation speed (in seconds)*
---@field box_sprite            [string, number, number, number]
---
--- The status of this recruit:
--- - As an integer, represents the recruit progress
--- - As a boolean, represents Recruited (`true`) or Lost (`false`)
--- 
--- *This value is saved to the save file*
---@field recruited         integer|boolean
---
--- Whether the recruit is hidden in the recruit menu \
--- *This value is saved to the save file*
---@field hidden            boolean
---
---@overload fun(...) : Recruit
local Recruit = Class()

function Recruit:init()
    self.name = "Test Recruit"

    self.recruit_amount = 1

    self.index = 1

    -- Selection Display

    self.description = "No description"
    self.chapter = 0
    self.level = 0
    self.attack = 0
    self.defense = 0
    self.element = "UNSET"
    self.like = "Undefined"
    self.dislike = "Undefined"

    self.box_gradient_type = "bright"

    self.box_gradient_color = {1,1,1,1}

    self.box_sprite = {nil, 0, 0, 4/30}

    self.recruited = 0

    self.hidden = false
end

---@return {id: string?, recruited: integer|boolean, hidden: boolean?}
function Recruit:save()
    local data = {
        id = self.id,
        recruited = self.recruited,
        hidden = self.hidden,
    }
    self:onSave(data)
    return data
end

---@param data {id: string?, recruited: integer|boolean?, hidden: boolean?}
function Recruit:load(data)
    self.recruited = data.recruited or self.recruited
    self.hidden = data.hidden or self.hidden

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
---@param v integer|boolean
function Recruit:setRecruited(v) self.recruited = v end

function Recruit:getHidden() return self.hidden end
---@param v boolean
function Recruit:setHidden(v) self.hidden = v end

--- *(Override)* Called when this recruit's data is saved to the save file
---@param data {id: string, recruited: integer|boolean, hidden: boolean}    The data that was saved.
function Recruit:onSave(data) end
--- *(Override)* Called when this recruit's data is loaded from the save file
---@param data {id: string?, recruited: integer|boolean?, hidden: boolean?}    The data that was loaded.
function Recruit:onLoad(data) end

return Recruit

