local StrUtil = {}

function StrUtil.endsWith(str, sub)
    return str:sub(-#sub) == sub, str:sub(1, -#sub-1)
end

function StrUtil.startsWith(str, sub)
    return str:sub(1, #sub) == sub, str:sub(#sub+1)
end

return StrUtil