local data = {
    loaded = false,
    data = {
        animations = {}
    },
    processed = {
        animations = {}
    }
}

function data.loadData(dat)
    data.data = dat

    -- post-processing animations
    data.processed.animations = {}
    for key,_ in pairs(data.data.animations) do
        data:processAnimation(key)
    end

    data.loaded = true
end

function data:processAnimation(anim)
    if data.processed.animations[anim] then
        return data.processed.animations[anim]
    end
    local anim_data = data.data.animations[anim]
    if anim_data.copy then
        data:processAnimation(anim_data.copy)
        local copy_data = data.data.animations[anim_data.copy]
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
    data.processed.animations[anim] = Animation(anim_data)
end

function data.getAnimationData(path)
    return data.data.animations[path]
end

function data.getAnimation(path)
    return data.processed.animations[path]
end

return data