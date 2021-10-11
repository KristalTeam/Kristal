local mods = {}

function mods.clear()
    mods.loaded = false
    mods.list = {}
    mods.data = {}
    mods.named = {}
end

function mods.loadData(data)
    for mod_id,mod_data in pairs(data) do
        if mods.data[mod_id] then
            local old_mod = mods.data[mod_id]
            if old_mod.name then
                mods.named[old_mod.name] = nil
            end
            utils.removeFromTable(mods.list, old_mod)
        end

        -- convert image data into images
        if mod_data.preview_data then
            mod_data.preview = {}
            for _,img_data in ipairs(mod_data.preview_data) do
                table.insert(mod_data.preview, love.graphics.newImage(img_data))
            end
        end

        mods.data[mod_id] = mod_data
        if mod_data.name then
            mods.named[mod_data.name] = mod_id
        end
        table.insert(mods.list, mods.data[mod_id])
    end
end

function mods.getMods()
    return mods.list
end

function mods.getMod(id)
    return mods.data[id] or (mods.named[id] and mods.data[mods.named[id]])
end

function mods.getName(id)
    return mods.data[id].name or id
end

return mods