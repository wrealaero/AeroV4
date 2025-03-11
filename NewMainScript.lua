local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
    if not isfile(path) then
        local repo = "QP-Offcial/VapeV4ForRoblox"  -- Default repo
        local filename = path:gsub("newvape/", "")

        -- Override repo for specific files
        if filename == "main.lua" or filename == "NewMainScript.lua" or filename == "universal.lua" then
            repo = "wrealaero/AeroV4"  -- Your GitHub
        end

        -- Use "main" if commit.txt is missing
        local commit = isfile("newvape/profiles/commit.txt") and readfile("newvape/profiles/commit.txt") or "main"

        -- Construct URL
        local url = "https://raw.githubusercontent.com/"..repo.."/"..commit.."/"..filename
        print("Downloading: " .. url)  -- Debug print

        -- Try to fetch the file
        local suc, res = pcall(function()
            return game:HttpGet(url, true)
        end)

        -- If it fails, print error
        if not suc or res == "404: Not Found" or res == "" then
            warn("Failed to download: " .. filename .. " | Error: " .. tostring(res))
            return
        end

        -- Save the file
        writefile(path, res)
    end
    return (func or readfile)(path)
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
