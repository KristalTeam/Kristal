return function(cutscene)
    cutscene:setSpeaker("susie")

    local text = love.filesystem.read("main.lua")
    local lines = Utils.split(text, "\r\n", true)
    if #lines == 1 then
        lines = Utils.split(text, "\n", true)
    end

    local new_lines = {}
    for i,line in ipairs(lines) do
        local new_line
        for i = 1, #line, 24 do
            if not new_line then
                new_line = "* "..line:sub(i, i+23)
            else
                new_line = new_line.."\n"..line:sub(i, i+23)
            end
        end
        table.insert(new_lines, new_line)
    end

    for _,line in ipairs(new_lines) do
        cutscene:text(line, "glasses")
    end
end
