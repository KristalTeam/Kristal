local ffi = require "ffi"

local name = "zip"

if ffi.os == "Windows" then
    name = name .. "-" .. ffi.arch
elseif ffi.os == "Linux" then
    name = "lib" .. name .. ".so"
end

local search_paths = { "", (love.filesystem.getRealDirectory("lib/") or "") .. "/lib/" }

local ok, zlib
for _, search_path in ipairs(search_paths) do
    ok, zlib = pcall(ffi.load, search_path .. name)

    if not zlib then
        ok = false
    end

    if ok then
        break
    end
end

if not ok then
    return
end

ffi.cdef [[
struct zip_t;

struct zip_t *zip_open(const char *zipname, int level, char mode);
int zip_entry_open(struct zip_t *zip, const char *entryname);
int zip_entry_write(struct zip_t *zip, const void *buf, size_t bufsize);
int zip_entry_close(struct zip_t *zip);
void zip_close(struct zip_t *zip);
]]

local Zip = {}

local function addEntries(directory, to, zip)
	local files = love.filesystem.getDirectoryItems(directory)
	for _,v in ipairs(files) do
		local file = directory.."/"..v
        local saveFile
        if to == "" then
            saveFile = v
        else
            saveFile = to.."/"..v
        end
        local info = love.filesystem.getInfo(file)
        if info then
            if info.type == "file" then
                print("Compressing "..file)
                local contents = love.filesystem.read(file)

                zlib.zip_entry_open(zip, saveFile)
                zlib.zip_entry_write(zip, contents, #contents)
                zlib.zip_entry_close(zip)
            elseif info.type == "directory" then
                print("Traversing "..file)
                addEntries(file, saveFile, zip)
            end
        end
	end
end

function Zip:compressToArchive(directory, to, zipName)
    local realToPath = love.filesystem.getRealDirectory(to).."/"..to
    local saveTo = realToPath.."/"..zipName

    local z = zlib.zip_open(saveTo, 6, string.byte('w'))
    addEntries(directory, "", z)
    zlib.zip_close(z)
end

return Zip