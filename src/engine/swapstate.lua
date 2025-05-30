---@class AssetSwapper
local AssetSwapper = {}

function AssetSwapper:draw()
    Draw.setColor(0.8,0.8,0.8)
    Draw.draw(self.image)
    Draw.setColor(1,1,1)
    Draw.printAlign("Swapping out assets...", SCREEN_WIDTH/2, SCREEN_HEIGHT/2, "center")
end

function AssetSwapper:unload(asset_type, asset_paths)
    if type(asset_paths) == "string" then asset_paths = {asset_paths} end
    if asset_type == "all" then
        for _, loader in ipairs({
            "sprites",
            "sounds",
            "music",
            "shaders",
            -- TODO: Implement these types
            -- "fonts",
            -- "videos",
            -- "bubbles",
        }) do
            self:unload(loader, asset_paths)
        end
        return
    end
    ---@generic T
    ---@param table table<string, T>
    ---@param side_effect fun(key:string, side_effect:T)?
    local function removePrefixed(table, side_effect)
        for key, asset in pairs(table) do
            local delete = false
            for _, path in ipairs(asset_paths) do
                if Utils.startsWith(key, path) then
                    delete = true
                    break
                end
            end
            if delete then
                table[key] = nil
                if side_effect then
                    side_effect(key, asset)
                end
            end
        end
    end
    if asset_type == "music" then
        Music.stop()
        removePrefixed(Assets.data.music)
    elseif asset_type == "sprites" then
        removePrefixed(Assets.data.frames)
        removePrefixed(Assets.data.frame_ids)
        removePrefixed(Assets.data.texture, function (key, asset)
            Assets.texture_ids[asset] = nil
            Assets.data.texture_data[key] = nil
        end)
    elseif asset_type == "shaders" then
        removePrefixed(Assets.data.shader_paths)
        removePrefixed(Assets.data.shaders)
    elseif asset_type == "sounds" then
        removePrefixed(Assets.data.sound_data)
        removePrefixed(Assets.sounds)
        removePrefixed(Assets.sound_instances, function (key, sounds)
            ---@cast sounds love.Source[]
            for _, sound in ipairs(sounds) do
                sound:stop()
            end
        end)
    else
        Kristal.Console:warn("Unloading "..asset_type.. " isn't implemented yet")
    end
    collectgarbage()
end

---@param _ Game
function AssetSwapper:enter(_, asset_type, asset_paths, after)
    print(_, asset_type, asset_paths)
    self.image = love.graphics.newImage(SCREEN_CANVAS:newImageData())
    assert(Mod, "no mod")
    assert(asset_type, "Unset asset type!")
    local load_count = 2
    self.after = after or function()end
    local finishLoadStep = function ()
        load_count = load_count - 1
        print("load_count",load_count)
        if load_count == 0 then
            if TARGET_MOD and RELEASE_MODE then
                Assets.saveData()
            end
            Gamestate.pop()

            Kristal.Stage.visible = true
            Kristal.Stage.active = true
            self.after()
        end
    end
    self:unload(asset_type, asset_paths)

    Kristal.loadAssets("", asset_type, asset_paths, finishLoadStep)
    Kristal.loadModAssets(Mod.info.id, asset_type, asset_paths, finishLoadStep)
end

return AssetSwapper