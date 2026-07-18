---@class EditorChoiceUtils
local EditorChoiceUtils = {}

---@param choice any
---@return any value
function EditorChoiceUtils.getValue(choice)
    if type(choice) ~= "table" then return choice end
    if choice.value ~= nil then return choice.value end
    return choice.id
end

---@param choice any
---@return string label
function EditorChoiceUtils.getLabel(choice)
    if type(choice) ~= "table" then return tostring(choice) end
    return tostring(choice.label or choice.name or EditorChoiceUtils.getValue(choice))
end

---@param source table|function|nil
---@param context? any
---@return table choices
function EditorChoiceUtils.resolve(source, context)
    if type(source) ~= "function" then return type(source) == "table" and source or {} end
    local success, choices = pcall(source, context)
    return success and type(choices) == "table" and choices or {}
end

---@param choices table
---@param value any
---@return any value
---@return string? label
function EditorChoiceUtils.find(choices, value)
    for _, choice in ipairs(choices or {}) do
        local choice_value = EditorChoiceUtils.getValue(choice)
        if choice_value == value or tostring(choice_value) == tostring(value) then
            return choice_value, EditorChoiceUtils.getLabel(choice)
        end
    end
end

return EditorChoiceUtils
