---@class EditorPropertyFields
local EditorPropertyFields = {}

function EditorPropertyFields.value(target, label, key, options)
    options = options or {}
    local numeric = options.numeric == true
    local compact = options.compact
    if compact == nil then compact = numeric end
    return {
        label = label,
        readonly = options.readonly == true,
        compact = compact,
        get = options.get or function()
            local value = target[key]
            if value ~= nil then return value end
            return options.default ~= nil and options.default or (numeric and 0 or "")
        end,
        set = function(value)
            if options.readonly then return false end
            if numeric then
                local input = value
                value = tonumber(value)
                if value == nil then
                    if options.on_invalid then options.on_invalid(input, label, key) end
                    return false
                end
            end
            target[key] = value
            if options.on_set then options.on_set(value, target, key) end
            return true
        end
    }
end

function EditorPropertyFields.number(target, label, key, options)
    options = TableUtils.copy(options or {})
    options.numeric = true
    return EditorPropertyFields.value(target, label, key, options)
end

function EditorPropertyFields.choice(target, label, key, choices, options)
    local field = EditorPropertyFields.value(target, label, key, options)
    field.choices = choices
    return field
end

function EditorPropertyFields.color(target, label, key, options)
    local field = EditorPropertyFields.value(target, label, key, options)
    field.control = "color"
    return field
end

function EditorPropertyFields.path(target, label, key, path_kind, options)
    local field = EditorPropertyFields.value(target, label, key, options)
    field.control = "path"
    field.path_kind = path_kind
    for option, value in pairs(options or {}) do field[option] = value end
    return field
end

function EditorPropertyFields.assetPath(target, label, key, options)
    return EditorPropertyFields.path(target, label, key, "asset", options)
end

function EditorPropertyFields.scriptPath(target, label, key, options)
    return EditorPropertyFields.path(target, label, key, "script", options)
end

return EditorPropertyFields
