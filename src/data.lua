local Data = {
    loaded = false,
    data = {
        animations = {}
    },
    processed = {
        animations = {}
    }
}

function Data:loadData(data)
    self.data = data

    -- post-processing animations
    self.processed.animations = {}
    for key,_ in pairs(self.data.animations) do
        self:processAnimation(key)
    end

    self.loaded = true
end

function Data:processAnimation(anim)
    if self.processed.animations[anim] then
        return self.processed.animations[anim]
    end
    local anim_data = self.data.animations[anim]
    if anim_data.copy then
        self:processAnimation(anim_data.copy)
        local copy_data = self.data.animations[anim_data.copy]
        for k,v in pairs(copy_data) do
            if anim_data[k] == nil then
                anim_data[k] = v
            end
        end
        if copy_data.states then
            for k,v in pairs(copy_data.states) do
                if anim_data.states[k] == nil then
                    anim_data.states[k] = v
                end
            end
        end
    end
    self.processed.animations[anim] = Animation(anim_data)
end

function Data:getAnimationData(path)
    return self.data.animations[path]
end

function Data:getAnimation(path)
    return self.processed.animations[path]
end

return Data