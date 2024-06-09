-- Contains helper functions to retrieve the current revision of the engine, in the case
-- it was cloned as a Git repo.
local GitFinder = {}

local git_file = love.filesystem.getInfo(".git")

-- If true, the engine is cloned as a git repo, the otherwise if false.
GitFinder.is_git_repo = git_file ~= nil

-- Whether probing the info of the repo simply with filesystem operations is possible.
--
-- If the engine is a submodule of another repo, this will be false.
-- In this case, the `.git` file will be plain text containing
-- `gitdir: path/to/true/git/folder`; it's likely not possible (considering LÖVE's sandbox)
-- and pointless to follow the semi-symlink.
GitFinder.is_probing_info_possible = GitFinder.is_git_repo and git_file.type == "directory"

-- Retrieves the engine's current commit (revision), if it was cloned as a Git repo. \
-- May fail if the engine is not a Git repo, the repo is broken, etc.
---@return string|nil commit The SHA-1 hash for the current commit, or nil in case of failure
function GitFinder:fetchCurrentCommit()
    if not GitFinder.is_probing_info_possible then return end

    -- Get current HEAD
    local head, _ = love.filesystem.read(".git/HEAD")
    if not head then return end
    -- Try to get the reference it may point to
    local ref = head:match("^ref: ([^\r\n]*)")
    if ref then -- HEAD is not detached
        -- Read the ref's correspending file, which contains the hash of the commit that it points to
        local commit, _ = love.filesystem.read(".git/" .. ref)
        return commit
    else -- HEAD is detached
        -- The file just contains the hash of the commit it's at
        return head
    end
end

-- Returns the first 7 characters of engine's current commit (revision).
---@return string|nil commit nil in case of failure
function GitFinder:fetchTrimmedCommit()
    if not GitFinder.is_probing_info_possible then return end

    local commit = self:fetchCurrentCommit()
    -- Check if we managed to obtain the current commit's hash
    if commit then
        -- Return the first 7 characters of it
        return commit:sub(1, 7)
    end
end

return GitFinder