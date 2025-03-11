local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil and res ~= ""
end
local function downloadFile(url, path)
    local suc, res = pcall(function() return game:HttpGet(url, true) end)
    if suc and res and res ~= "404: Not Found" then
        writefile(path, res)
        print("Downloaded: " .. path)
    else
        warn("Failed to download: " .. path .. " | Error: " .. tostring(res))
    end
end

-- Create necessary folders
for _, folder in {"newvape", "newvape/games", "newvape/profiles", "newvape/assets", "newvape/libraries", "newvape/guis"} do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

-- Download main.lua from your GitHub
local repo = "wrealaero/AeroV4"
local url = "https://raw.githubusercontent.com/" .. repo .. "/main/main.lua"
downloadFile(url, "newvape/main.lua")

-- Execute main.lua
if isfile("newvape/main.lua") then
    loadstring(readfile("newvape/main.lua"))()
else
    warn("main.lua was not downloaded successfully.")
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/QP-Offcial/VapeV4ForRoblox')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
