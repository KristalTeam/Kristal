---@class EditorMapExporter : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorMapExporter
local EditorMapExporter = Class()

EditorMapExporter.TILE_SIZE = 4096
--- basically, the issue is that Love2d does not have a real png stream export method, so we're limited mostly by memory. This warns you if the export will use comically large amounts\
--- proceeding after that point is your choice (and might take nine years)
EditorMapExporter.LARGE_EXPORT_BYTES = 512 * 1024 * 1024

function EditorMapExporter:init(editor)
    self.editor = editor
end

function EditorMapExporter:getFocusedEntry(document)
    local map_id = document.map_view and document.map_view:getFocusedMapId()
        or document.primary_map_id
    return map_id and document.map_lookup[map_id] or nil
end

function EditorMapExporter:getDefaultPath(kind, document)
    local id
    if kind == "world" then
        id = document.world and document.world.id or "world"
    else
        local entry = self:getFocusedEntry(document)
        id = entry and entry.id or "map"
    end
    id = tostring(id):gsub("[^%w%._%-/]+", "_"):gsub("^/+", "")
    return "exports/" .. (kind == "world" and "worlds/" or "maps/") .. id .. ".png"
end

function EditorMapExporter:getEntries(kind, document)
    if kind == "map" then
        local entry = self:getFocusedEntry(document)
        return entry and { entry } or nil, entry and nil or "No focused/open map is available"
    end
    if not document.editor_world or not document.world or #document.maps == 0 then
        return nil, "No open world is available"
    end
    local entries = {}
    local focused = self:getFocusedEntry(document)
    for _, entry in ipairs(document.maps) do
        if entry ~= focused then table.insert(entries, entry) end
    end
    if focused then table.insert(entries, focused) end
    return entries
end

function EditorMapExporter:getBounds(document, entries)
    for _, entry in ipairs(entries) do
        if not document:getPreview(entry) then
            return nil, nil, nil, nil, "Could not build a preview for map '" .. tostring(entry.id) .. "'"
        end
    end
    local min_x, min_y = entries[1].x, entries[1].y
    local max_x = entries[1].x + (entries[1].width or 0)
    local max_y = entries[1].y + (entries[1].height or 0)
    for index = 2, #entries do
        local entry = entries[index]
        min_x, min_y = math.min(min_x, entry.x), math.min(min_y, entry.y)
        max_x = math.max(max_x, entry.x + (entry.width or 0))
        max_y = math.max(max_y, entry.y + (entry.height or 0))
    end
    return math.floor(min_x), math.floor(min_y), math.ceil(max_x), math.ceil(max_y)
end

function EditorMapExporter:getRenderPlan(document, entries, options)
    options = options or {}
    local min_x, min_y, max_x, max_y, reason = self:getBounds(document, entries)
    if not min_x then return nil, reason end
    local scale = tonumber(options.scale) or 1
    if scale <= 0 or scale ~= scale or scale == math.huge then
        return nil, "Export scale must be a finite number greater than zero"
    end
    local width = math.ceil((max_x - min_x) * scale)
    local height = math.ceil((max_y - min_y) * scale)
    if width < 1 or height < 1 then return nil, "The export area is empty" end
    return {
        min_x = min_x, min_y = min_y, max_x = max_x, max_y = max_y,
        width = width, height = height, scale = scale,
        estimated_bytes = width * height * 4
    }
end

function EditorMapExporter:formatMemory(bytes)
    if bytes >= 1024 * 1024 * 1024 then return string.format("%.2f GiB", bytes / (1024 * 1024 * 1024)) end
    return string.format("%.1f MiB", bytes / (1024 * 1024))
end

function EditorMapExporter:confirmLargeExport(plans)
    local largest
    for _, plan in ipairs(plans) do
        if not largest or plan.estimated_bytes > largest.estimated_bytes then largest = plan end
    end
    if not largest or largest.estimated_bytes <= self.LARGE_EXPORT_BYTES then return true end
    local pressed = love.window.showMessageBox("Large PNG Export",
        string.format("The largest output is %dx%d and needs at least %s of memory to complete. "
            .. "The editor will temporarily use additional memory, which may slow down weaker devices. Continue?",
            largest.width, largest.height, self:formatMemory(largest.estimated_bytes)),
        { "Continue", "Cancel", enterbutton = 1, escapebutton = 2 }, "warning", true)
    return pressed == 1
end

function EditorMapExporter:render(document, entries, options, plan)
    options = options or {}
    local reason
    if not plan then plan, reason = self:getRenderPlan(document, entries, options) end
    if not plan then return nil, reason end
    local width, height, scale = plan.width, plan.height, plan.scale
    local limit = love.graphics.getSystemLimits().texturesize
    local tile_size = math.max(1, math.min(self.TILE_SIZE, limit))
    local canvas_width, canvas_height = math.min(tile_size, width), math.min(tile_size, height)

    local previous_canvas = love.graphics.getCanvas()
    love.graphics.push("all")
    local success, contents, export_width, export_height = pcall(function()
        local image_data = love.image.newImageData(width, height, "rgba8")
        local canvas = love.graphics.newCanvas(canvas_width, canvas_height, { dpiscale = 1 })
        canvas:setFilter("nearest", "nearest")
        for tile_y = 0, height - 1, tile_size do
            for tile_x = 0, width - 1, tile_size do
                local tile_width = math.min(tile_size, width - tile_x)
                local tile_height = math.min(tile_size, height - tile_y)
                love.graphics.setCanvas(canvas)
                love.graphics.setScissor()
                love.graphics.clear(0, 0, 0, 0)
                love.graphics.setShader()
                love.graphics.setScissor(0, 0, tile_width, tile_height)
                love.graphics.setStencilTest()
                love.graphics.setBlendMode("alpha", "alphamultiply")
                love.graphics.setColor(1, 1, 1, 1)
                for _, entry in ipairs(entries) do
                    love.graphics.origin()
                    love.graphics.translate(-tile_x, -tile_y)
                    love.graphics.scale(scale, scale)
                    love.graphics.translate(entry.x - plan.min_x, entry.y - plan.min_y)
                    document:drawPreview(entry, 1 / scale, true, {
                        export = true,
                        include_background = options.include_background ~= false,
                        include_objects = options.include_objects ~= false
                    })
                end
                love.graphics.setCanvas(previous_canvas)
                local tile_data = canvas:newImageData(1, 1, 0, 0, tile_width, tile_height)
                image_data:paste(tile_data, tile_x, tile_y, 0, 0, tile_width, tile_height)
                tile_data:release()
            end
        end
        local png = image_data:encode("png")
        local contents = png:getString()
        png:release()
        image_data:release()
        canvas:release()
        return contents, width, height
    end)
    love.graphics.setCanvas(previous_canvas)
    love.graphics.pop()
    if not success then return nil, tostring(contents) end
    return contents, export_width, export_height
end

function EditorMapExporter:getProjectPath(path)
    path = StringUtils.trim(tostring(path or "")):gsub("\\", "/")
    if path == "" then return nil, "Choose an export path" end
    if not path:lower():match("%.png$") then path = path .. ".png" end
    return ProjectFileSystem.getProjectPath(path)
end

function EditorMapExporter:getIndividualMapPath(world_path, map_id)
    local directory = world_path:gsub("%.[Pp][Nn][Gg]$", "")
    local id = tostring(map_id):gsub("\\", "/"):gsub("[^%w%._%-/]+", "_"):gsub("^/+", "")
    return directory .. "/" .. id .. ".png", directory
end

function EditorMapExporter:confirmOverwrite(paths)
    local existing = {}
    for _, path in ipairs(paths) do
        if ProjectFileSystem.getInfo(path) then table.insert(existing, path) end
    end
    if #existing == 0 then return true end
    local message = #existing == 1 and ("Replace the existing file '" .. existing[1] .. "'?")
        or string.format("Replace %d existing PNG files?", #existing)
    local pressed = love.window.showMessageBox("Overwrite PNG", message,
        { "Overwrite", "Cancel", enterbutton = 1, escapebutton = 2 }, "warning", true)
    return pressed == 1
end

function EditorMapExporter:export(kind, document, path, options)
    options = options or {}
    local entries, reason = self:getEntries(kind, document)
    if not entries then return false, reason end
    local project_path
    project_path, reason = self:getProjectPath(path)
    if not project_path then return false, reason end

    local jobs, paths, plans = {}, {}, {}
    if kind == "world" and options.individual_maps == true then
        local world_path = project_path
        local output_directory
        for _, entry in ipairs(entries) do
            local individual_path, directory = self:getIndividualMapPath(world_path, entry.id)
            local plan
            plan, reason = self:getRenderPlan(document, { entry }, options)
            if not plan then return false, reason end
            table.insert(jobs, { entries = { entry }, path = individual_path, plan = plan })
            table.insert(paths, individual_path)
            table.insert(plans, plan)
            output_directory = directory
        end
        project_path = output_directory
    else
        local plan
        plan, reason = self:getRenderPlan(document, entries, options)
        if not plan then return false, reason end
        table.insert(jobs, { entries = entries, path = project_path, plan = plan })
        table.insert(paths, project_path)
        table.insert(plans, plan)
    end
    if not self:confirmOverwrite(paths) then return false, "Choose another path or cancel" end
    if not self:confirmLargeExport(plans) then return false, "Export cancelled" end

    for _, job in ipairs(jobs) do
        local contents, width
        contents, width = self:render(document, job.entries, options, job.plan)
        if not contents then return false, width end
        local written
        written, reason = ProjectFileSystem.writeFile(job.path, contents)
        if not written then return false, reason end
    end
    if self.editor.file_browser then self.editor.file_browser:refresh(paths[#paths]) end
    return true, project_path, {
        count = #jobs,
        individual = kind == "world" and options.individual_maps == true,
        width = jobs[1] and jobs[1].plan.width,
        height = jobs[1] and jobs[1].plan.height
    }
end

function EditorMapExporter:openDialog(kind)
    local document = self.editor.active_document
    if not document then return false end
    if kind == "world" and not document.editor_world then return false end
    local success_message
    local variables = { {
        id = "path", name = "Project Path", type = "string", code_name = false,
        description = "Output path (relative to open project)"
    }, {
        id = "scale", name = "Export Scale", type = "number", code_name = false,
        description = "Scale multiplier. '1' is equal to that of ingame."
    }, {
        id = "include_background", name = "Include Background", type = "boolean",
        code_name = false
    }, {
        id = "include_objects", name = "Include Objects", type = "boolean",
        code_name = false
    } }
    if kind == "world" then
        table.insert(variables, {
            id = "individual_maps", name = "Export Maps Individually", type = "boolean",
            code_name = false,
            description = "Creates a folder containing each map in this world rather than a single stitched image."
        })
    end
    return self.editor:openCreationDialog({
        title = kind == "world" and "Export World as PNG" or "Export Map as PNG",
        create_label = "Export",
        success_message = function()
            return success_message or "Exported PNG"
        end,
        templates = { {
            id = "png_export", category = "Export",
            name = kind == "world" and "World PNG" or "Map PNG",
            variables = variables
        } },
        context = { defaults = {
            path = self:getDefaultPath(kind, document), scale = 1,
            include_background = true, include_objects = true, individual_maps = false
        } },
        on_create = function(values)
            local success, path, result = self:export(kind, document, values.path, {
                scale = values.scale,
                include_background = values.include_background,
                include_objects = values.include_objects,
                individual_maps = values.individual_maps
            })
            if not success then return false, path end
            success_message = result.individual
                and string.format("Exported %d map PNGs: %s", result.count, path)
                or string.format("Exported %dx%d PNG: %s", result.width, result.height, path)
            return true
        end
    })
end

return EditorMapExporter
