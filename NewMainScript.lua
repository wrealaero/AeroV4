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
        if filename == "main.lua" or filename == "newmainscript.lua" or filename == "universal.lua" then
            repo = "wrealaero/AeroV4"  -- Your GitHub
        end

        -- Check if commit.txt exists; if not, use "main"
        local commit = isfile("newvape/profiles/commit.txt") and readfile("newvape/profiles/commit.txt") or "main"

        -- Debugging message
        print("Downloading: " .. filename .. " from " .. repo .. " (commit: " .. commit .. ")")

        -- Try to fetch the file from GitHub
        local suc, res = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/"..repo.."/"..commit.."/"..filename, true)
        end)

        -- If the request fails, print the error and stop
        if not suc or res == "404: Not Found" or res == "" then
            warn("Failed to download: " .. filename .. " | Error: " .. tostring(res))
            return
        end

        -- Add watermark for cache clearing
        if path:find(".lua") then
            res = "--This watermark is used to delete the file if it's cached, remove it to make the file persist after Vape updates.\n" .. res
        end

        -- Save the file
        writefile(path, res)
    end
    return (func or readfile)(path)
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
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
