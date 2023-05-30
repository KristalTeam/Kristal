local GitFinder = {}

function GitFinder:FetchCurrentCommit()
    -- Check if the .git directory exists
    if love.filesystem.getInfo(".git") then
        -- Check if the HEAD file exists
        if love.filesystem.getInfo(".git/HEAD") then
            -- Read the file
            local head = love.filesystem.read(".git/HEAD")
            -- Check if the file contains a reference
            if head:find("ref: ") then
                -- Get the reference, stripping any newlines
                local ref = head:match("ref: (.*)"):gsub("\n", ""):gsub("\r", "")
                -- Check if the reference exists
                if love.filesystem.getInfo(".git/" .. ref) then
                    -- Read the reference
                    local commit = love.filesystem.read(".git/" .. ref)
                    -- Return the commit
                    return commit
                end
            else
                -- Return the commit
                return head
            end
        end
    end
end

function GitFinder:FetchTrimmedCommit()
    -- Fetch the current commit
    local commit = self:FetchCurrentCommit()
    -- Check if the commit exists
    if commit then
        -- Trim the commit
        return commit:sub(1, 7)
    end
end

return GitFinder