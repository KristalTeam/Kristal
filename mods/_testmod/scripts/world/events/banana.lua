local Banana, super = Class(Event)

function Banana:init(data)
    super.init(self, data.center_x, data.center_y, {data.width, data.height})

    self:setOrigin(0.5, 0.5)
    self:setSprite("banana", 0.25)

    self.mouse_collider = CircleCollider(self, data.width, data.height, 20)
end

function Banana:onCollide(chara)
    Assets.playSound("item")

    self:setFlag("dont_load", true)

    if chara:includes(ChaserEnemy) then
        if chara.actor.id == "virovirokun" then
            chara:setFlag("bananas", chara:getFlag("bananas", 0) + 1)
            if chara:getFlag("bananas") == 9 then
                Assets.playSound("won")
                local npc = chara:convertToNPC({text = "* I had severe potassium\ndeficiency"})
                npc:setSprite("spared")
                Game:setFlag("viroviro_banana", true)
            end
        end
    end

    self:remove()
end

function Banana:draw()
    super.draw(self)
    if DEBUG_RENDER then
        self.mouse_collider:draw(0, 0, 1, 1)
    end
end

return Banana