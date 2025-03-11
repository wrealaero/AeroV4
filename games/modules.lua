--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/AeroV4/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local btext = function(text)
	return text..' '
end

local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local vapeConnections
if shared.vapeConnections and type(shared.vapeConnections) == "table" then vapeConnections = shared.vapeConnections else vapeConnections = {}; shared.vapeConnections = vapeConnections; end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local collectionService = cloneref(game:GetService("CollectionService"))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local GuiLibrary = shared.GuiLibrary
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local activeTweens = {}
local activeAnimationTrack = nil
local activeModel = nil
local emoteActive = false
 
local XStore = {
	bedtable = {},
	Tweening = false
}

local function GetEnumItems(enum)
	local fonts = {}
	for i,v in next, Enum[enum]:GetEnumItems() do 
		table.insert(fonts, v.Name) 
	end
	return fonts
end

local isAlive = function(plr, healthblacklist)
	plr = plr or lplr
	local alive = false 
	if plr.Character and plr.Character.PrimaryPart and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Head") then 
		alive = true
	end
	if not healthblacklist and alive and plr.Character.Humanoid.Health and plr.Character.Humanoid.Health <= 0 then 
		alive = false
	end
	return alive
end
local function GetMagnitudeOf2Objects(part, part2, bypass)
	local magnitude, partcount = 0, 0
	if not bypass then 
		local suc, res = pcall(function() return part.Position end)
		partcount = suc and partcount + 1 or partcount
		suc, res = pcall(function() return part2.Position end)
		partcount = suc and partcount + 1 or partcount
	end
	if partcount > 1 or bypass then 
		magnitude = bypass and (part - part2).magnitude or (part.Position - part2.Position).magnitude
	end
	return magnitude
end
local function GetTopBlock(position, smart, raycast, customvector)
	position = position or isAlive(lplr, true) and lplr.Character:WaitForChild("HumanoidRootPart").Position
	if not position then 
		return nil 
	end
	if raycast and not game.Workspace:Raycast(position, Vector3.new(0, -2000, 0), store.blockRaycast) then
	    return nil
    end
	local lastblock = nil
	for i = 1, 500 do 
		local newray = game.Workspace:Raycast(lastblock and lastblock.Position or position, customvector or Vector3.new(0.55, 999999, 0.55), store.blockRaycast)
		local smartest = newray and smart and game.Workspace:Raycast(lastblock and lastblock.Position or position, Vector3.new(0, 5.5, 0), store.blockRaycast) or not smart
		if newray and smartest then
			lastblock = newray
		else
			break
		end
	end
	return lastblock
end
local function FindEnemyBed(maxdistance, highest)
	local target = nil
	local distance = maxdistance or math.huge
	local whitelistuserteams = {}
	local badbeds = {}
	if not lplr:GetAttribute("Team") then return nil end
	for i,v in pairs(playersService:GetPlayers()) do
		if v ~= lplr then
			local type, attackable = vape.Libraries.whitelist:get(v)
			if not attackable then
				whitelistuserteams[v:GetAttribute("Team")] = true
			end
		end
	end
	for i,v in pairs(collectionService:GetTagged("bed")) do
			local bedteamstring = string.split(v:GetAttribute("id"), "_")[1]
			if whitelistuserteams[bedteamstring] ~= nil then
			   badbeds[v] = true
		    end
	    end
	for i,v in pairs(collectionService:GetTagged("bed")) do
		if v:GetAttribute("id") and v:GetAttribute("id") ~= lplr:GetAttribute("Team").."_bed" and badbeds[v] == nil and lplr.Character and lplr.Character.PrimaryPart then
			if v:GetAttribute("NoBreak") or v:GetAttribute("PlacedByUserId") and v:GetAttribute("PlacedByUserId") ~= 0 then continue end
			local magdist = GetMagnitudeOf2Objects(lplr.Character.PrimaryPart, v)
			if magdist < distance then
				target = v
				distance = magdist
			end
		end
	end
	local coveredblock = highest and target and GetTopBlock(target.Position, true)
	if coveredblock then
		target = coveredblock.Instance
	end
	return target
end
local function FindTeamBed()
	local bedstate, res = pcall(function()
		return lplr.leaderstats.Bed.Value
	end)
	return bedstate and res and res ~= nil and res == "✅"
end
local function FindItemDrop(item)
	local itemdist = nil
	local dist = math.huge
	local function abletocalculate() return lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") end
    for i,v in pairs(collectionService:GetTagged("ItemDrop")) do
		if v and v.Name == item and abletocalculate() then
			local itemdistance = GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v)
			if itemdistance < dist then
			itemdist = v
			dist = itemdistance
		end
		end
	end
	return itemdist
end
local function FindTarget(dist, blockRaycast, includemobs, healthmethod)
	local whitelist = vape.Libraries.whitelist
	local sort, entity = healthmethod and math.huge or dist or math.huge, {}
	local function abletocalculate() return lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") end
	local sortmethods = {Normal = function(entityroot, entityhealth) return abletocalculate() and GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), entityroot) < sort end, Health = function(entityroot, entityhealth) return abletocalculate() and entityhealth < sort end}
	local sortmethod = healthmethod and "Health" or "Normal"
	local function raycasted(entityroot) return abletocalculate() and blockRaycast and game.Workspace:Raycast(entityroot.Position, Vector3.new(0, -2000, 0), store.blockRaycast) or not blockRaycast and true or false end
	for i,v in pairs(playersService:GetPlayers()) do
		if v ~= lplr and abletocalculate() and isAlive(v) and v.Team ~= lplr.Team then
			if not ({whitelist:get(v)})[2] then 
				continue
			end
			if sortmethods[sortmethod](v.Character.HumanoidRootPart, v.Character:GetAttribute("Health") or v.Character.Humanoid.Health) and raycasted(v.Character.HumanoidRootPart) then
				sort = healthmethod and v.Character.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.Character.HumanoidRootPart)
				entity.Player = v
				entity.Human = true 
				entity.RootPart = v.Character.HumanoidRootPart
				entity.Humanoid = v.Character.Humanoid
			end
		end
	end
	if includemobs then
		local maxdistance = dist or math.huge
		for i,v in pairs(store.pots) do
			if abletocalculate() and v.PrimaryPart and GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart) < maxdistance then
			entity.Player = {Character = v, Name = "PotEntity", DisplayName = "PotEntity", UserId = 1}
			entity.Human = false
			entity.RootPart = v.PrimaryPart
			entity.Humanoid = {Health = 1, MaxHealth = 1}
			end
		end
		for i,v in pairs(collectionService:GetTagged("DiamondGuardian")) do 
			if v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health and abletocalculate() then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "DiamondGuardian", DisplayName = "DiamondGuardian", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("GolemBoss")) do
			if v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health and abletocalculate() then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "Titan", DisplayName = "Titan", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("Drone")) do
			local plr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
			if plr and plr ~= lplr and plr.Team and lplr.Team and plr.Team ~= lplr.Team and ({VoidwareFunctions:GetPlayerType(plr)})[2] and abletocalculate() and v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
					sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
					entity.Player = {Character = v, Name = "Drone", DisplayName = "Drone", UserId = 1}
					entity.Human = false
					entity.RootPart = v.PrimaryPart
					entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("Monster")) do
			if v:GetAttribute("Team") ~= lplr:GetAttribute("Team") and abletocalculate() and v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "Monster", DisplayName = "Monster", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
			end
		end
	end
    end
    return entity
end

local vapeAssert = function(argument, title, text, duration, hault, moduledisable, module) 
	if not argument then
    local suc, res = pcall(function()
    local notification = GuiLibrary.CreateNotification(title or "Voidware", text or "Failed to call function.", duration or 20, "assets/WarningNotification.png")
    notification.IconLabel.ImageColor3 = Color3.new(220, 0, 0)
    notification.Frame.Frame.ImageColor3 = Color3.new(220, 0, 0)
    if moduledisable and (module and vape.Modules[module].Enabled) then vape.Modules[module]:Toggle(false) end
    end)
    if hault then while true do task.wait() end end end
end

local function spinParts(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "Middle" or part.Name == "Outer") then
            local tweenInfo, goal
            if part.Name == "Middle" then
                tweenInfo = TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
                goal = { Orientation = part.Orientation + Vector3.new(0, -360, 0) }
            elseif part.Name == "Outer" then
                tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
                goal = { Orientation = part.Orientation + Vector3.new(0, 360, 0) }
            end
 
            local tween = tweenService:Create(part, tweenInfo, goal)
            tween:Play()
            table.insert(activeTweens, tween)
        end
    end
end
 
local function placeModelUnderLeg()
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
 
    if humanoidRootPart then
        local assetsFolder = replicatedStorage:FindFirstChild("Assets")
        if assetsFolder then
            local effectsFolder = assetsFolder:FindFirstChild("Effects")
            if effectsFolder then
                local modelTemplate = effectsFolder:FindFirstChild("NightmareEmote")
                if modelTemplate and modelTemplate:IsA("Model") then
                    local clonedModel = modelTemplate:Clone()
                    clonedModel.Parent = workspace
 
                    if clonedModel.PrimaryPart then
                        clonedModel:SetPrimaryPartCFrame(humanoidRootPart.CFrame - Vector3.new(0, 3, 0))
                    else
                        warn("PrimaryPart not set for NightmareEmote model!")
                        return
                    end
 
                    spinParts(clonedModel)
                    activeModel = clonedModel
                else
                    warn("NightmareEmote model not found or is not a valid model!")
                end
            else
                warn("Effects folder not found in Assets!")
            end
        else
            warn("Assets folder not found in ReplicatedStorage!")
        end
    else
        warn("HumanoidRootPart not found in character!")
    end
end
 
local function playAnimation(animationId)
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
 
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        activeAnimationTrack = animator:LoadAnimation(animation)
        activeAnimationTrack:Play()
    else
        warn("Humanoid not found in character!")
    end
end
 
local function stopEffects()
    for _, tween in ipairs(activeTweens) do
        tween:Cancel()
    end
    activeTweens = {}
 
    if activeAnimationTrack then
        activeAnimationTrack:Stop()
        activeAnimationTrack = nil
    end
 
    if activeModel then
        activeModel:Destroy()
        activeModel = nil
    end
 
    emoteActive = false
end
 
local function monitorWalking()
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
 
    if humanoid then
        humanoid.Running:Connect(function(speed)
            if speed > 0 and emoteActive then
                stopEffects()
            end
        end)
    else
        warn("Humanoid not found in character!")
    end
end
 
local function activateNightmareEmote()
    if emoteActive then
        return
    end
 
    emoteActive = true
    local success, err = pcall(function()
        monitorWalking()
        placeModelUnderLeg()
        playAnimation("rbxassetid://9191822700")
    end)
 
    if not success then
        warn("Error occurred: " .. tostring(err))
        emoteActive = false
    end
end


run(function()
    local tppos2 = nil
    local TweenSpeed = 0.7
    local HeightOffset = 5
    local BedTP = {}

    local function teleportWithTween(char, destination)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            destination = destination + Vector3.new(0, HeightOffset, 0)
            local currentPosition = root.Position
            if (destination - currentPosition).Magnitude > 0.5 then
                local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                local goal = {CFrame = CFrame.new(destination)}
                local tween = TweenService:Create(root, tweenInfo, goal)
                tween:Play()
                tween.Completed:Wait()
				BedTP:Toggle(false)
            end
        end
    end

    local function killPlayer(player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end

    local function getEnemyBed(range)
        range = range or math.huge
        local bed = nil
        local player = lplr

        if not isAlive(player, true) then 
            return nil 
        end

        local localPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or Vector3.zero
        local playerTeam = player:GetAttribute('Team')
        local beds = collectionService:GetTagged('bed')

        for _, v in ipairs(beds) do 
            if v:GetAttribute('PlacedByUserId') == 0 then
                local bedTeam = v:GetAttribute('id'):sub(1, 1)
                if bedTeam ~= playerTeam then 
                    local bedPosition = v.Position
                    local bedDistance = (localPos - bedPosition).Magnitude
                    if bedDistance < range then 
                        bed = v
                        range = bedDistance
                    end
                end
            end
        end

        if not bed then 
            warningNotification("BedTP", 'No enemy beds found. Total beds: '..#beds, 5)
        else
            --warningNotification("BedTP", 'Teleporting to bed at position: '..tostring(bed.Position), 3)
			warningNotification("BedTP", 'Teleporting to bed at position: '..tostring(bed.Position), 3)
        end

        return bed
    end

    BedTP = vape.Categories.Modules:CreateModule({
        ["Name"] = "BedTP",
        ["Function"] = function(callback)
            if callback then
				task.spawn(function()
					repeat task.wait() until vape.Modules.Invisibility
					repeat task.wait() until vape.Modules.GamingChair
					if vape.Modules.Invisibility.Enabled and vape.Modules.GamingChair.Enabled then
						errorNotification("BedTP", "Please turn off the Invisibility and GamingChair module!", 3)
						BedTP:Toggle()
						return
					end
					if vape.Modules.Invisibility.Enabled then
						errorNotification("BedTP", "Please turn off the Invisibility module!", 3)
						BedTP:Toggle()
						return
					end
					if vape.Modules.GamingChair.Enabled then
						errorNotification("BedTP", "Please turn off the GamingChair module!", 3)
						BedTP:Toggle()
						return
					end
					BedTP:Clean(lplr.CharacterAdded:Connect(function(char)
						if tppos2 then 
							task.spawn(function()
								local root = char:WaitForChild("HumanoidRootPart", 9000000000)
								if root and tppos2 then 
									teleportWithTween(char, tppos2 + Vector3.new(0,10,0))
									tppos2 = nil
								end
							end)
						end
					end))
					local bed = getEnemyBed()
					if bed then 
						tppos2 = bed.Position
						killPlayer(lplr)
					else
						BedTP:Toggle(false)
					end
				end)
            end
        end
    })
end)

run(function()
	local TweenService = game:GetService("TweenService")
	local playersService = game:GetService("Players")
	local lplr = playersService.LocalPlayer
	
	local tppos2
	local deathtpmod = {["Enabled"] = false}
	local HeightOffset = 5

	local function teleportWithTween(char, destination)
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			destination = destination + Vector3.new(0, HeightOffset, 0)
			local currentPosition = root.Position
			if (destination - currentPosition).Magnitude > 0.5 then
				local tweenInfo = TweenInfo.new(0.65, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
				local goal = {CFrame = CFrame.new(destination)}
				local tween = TweenService:Create(root, tweenInfo, goal)
				tween:Play()
				tween.Completed:Wait()
			end
		end
	end

	local function killPlayer(player)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end

	local function onCharacterAdded(char)
		if tppos2 then 
			task.spawn(function()
				local root = char:WaitForChild("HumanoidRootPart", 9000000000)
				if root and tppos2 then 
					teleportWithTween(char, tppos2)
					tppos2 = nil
				end
			end)
		end
	end

	vapeConnections[#vapeConnections + 1] = lplr.CharacterAdded:Connect(onCharacterAdded)

	local function setTeleportPosition()
		local UserInputService = game:GetService("UserInputService")
		local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

		if isMobile then
			warningNotification("DeathTP", "Please tap on the screen to set TP position.", 3)
			local connection
			connection = UserInputService.TouchTapInWorld:Connect(function(inputPosition, processedByUI)
				if not processedByUI then
					local mousepos = lplr:GetMouse().UnitRay
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {game.Workspace.Map, game.Workspace:FindFirstChild("SpectatorPlatform")}
					rayparams.FilterType = Enum.RaycastFilterType.Whitelist
					local ray = game.Workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
					if ray then 
						tppos2 = ray.Position 
						warningNotification("DeathTP", "Set TP Position. Resetting to teleport...", 3)
						killPlayer(lplr)
					end
					connection:Disconnect()
					deathtpmod["ToggleButton"](false)
				end
			end)
		else
			local mousepos = lplr:GetMouse().UnitRay
			local rayparams = RaycastParams.new()
			rayparams.FilterDescendantsInstances = {game.Workspace.Map, game.Workspace:FindFirstChild("SpectatorPlatform")}
			rayparams.FilterType = Enum.RaycastFilterType.Whitelist
			local ray = game.Workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
			if ray then 
				tppos2 = ray.Position 
				warningNotification("DeathTP", "Set TP Position. Resetting to teleport...", 3)
				killPlayer(lplr)
			end
			deathtpmod["ToggleButton"](false)
		end
	end

	deathtpmod = vape.Categories.Modules:CreateModule({
		["Name"] = "DeathTP",
		["Function"] = function(calling)
			if calling then
				task.spawn(function()
					repeat task.wait() until vape.Modules.Invisibility
					repeat task.wait() until vape.Modules.GamingChair
					if vape.Modules.Invisibility.Enabled and vape.Modules.GamingChair.Enabled then
						errorNotification("DeathTP", "Please turn off the Invisibility and GamingChair module!", 3)
						deathtpmod:Toggle()
						return
					end
					if vape.Modules.Invisibility.Enabled then
						errorNotification("DeathTP", "Please turn off the Invisibility module!", 3)
						deathtpmod:Toggle()
						return
					end
					if vape.Modules.GamingChair.Enabled then
						errorNotification("DeathTP", "Please turn off the GamingChair module!", 3)
						deathtpmod:Toggle()
						return
					end
					local canRespawn = function() end
					canRespawn = function()
						local success, response = pcall(function() 
							return lplr.leaderstats.Bed.Value == '✅' 
						end)
						return success and response 
					end
					if not canRespawn() then 
						warningNotification("DeathTP", "Unable to use DeathTP without bed!", 5)
						deathtpmod:Toggle()
					else
						setTeleportPosition()
					end
				end)
			end
		end
	})
end)

local function GetTarget()
	return entitylib.EntityPosition({
		Part = 'RootPart',
		Range = 1000,
		Players = true,
		NPCs = false,
		Wallcheck = false
	})
end

run(function()
	local PlayerTP
	local PlayerTPTeleport = {Value = 'Respawn'}
	local PlayerTPSort = {Value = 'Distance'}
	local PlayerTPMethod = {Value = 'Linear'}
	local PlayerTPAutoSpeed = {}
	local PlayerTPSpeed = {Value = 200}
	local PlayerTPTarget = {Value = ''}
	local playertween
	local oldmovefunc
	local bypassmethods = {
		Respawn = function() 
			if isEnabled('InfiniteFly') then 
				return 
			end
			if not canRespawn() then 
				return 
			end
			for i = 1, 30 do 
				if isAlive(lplr, true) and lplr.Character:WaitForChild("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead then
					lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
					lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
				end
			end
			lplr.CharacterAdded:Wait()
			repeat task.wait() until isAlive(lplr, true) 
			task.wait(0.1)
			local target = GetTarget(nil, PlayerTPSort.Value == 'Health', true)
			if target.RootPart == nil or not PlayerTP.Enabled then 
				return
			end
			local localposition = lplr.Character:WaitForChild("HumanoidRootPart").Position
			local tweenspeed = (PlayerTPAutoSpeed.Enabled and ((target.RootPart.Position - localposition).Magnitude / 470) + 0.001 * 2 or (PlayerTPSpeed.Value / 1000) + 0.1)
			local tweenstyle = (PlayerTPAutoSpeed.Enabled and Enum.EasingStyle.Linear or Enum.EasingStyle[PlayerTPMethod.Value])
			playertween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(tweenspeed, tweenstyle), {CFrame = target.RootPart.CFrame}) 
			playertween:Play() 
			playertween.Completed:Wait()
		end,
		Instant = function() 
			local target = GetTarget(nil, PlayerTPSort.Value == 'Health', true)
			if target.RootPart == nil then 
				return PlayerTP:Toggle()
			end
			lplr.Character:WaitForChild("HumanoidRootPart").CFrame = (target.RootPart.CFrame + Vector3.new(0, 5, 0)) 
			PlayerTP:Toggle()
		end,
		Recall = function()
			if not isAlive(lplr, true) or lplr.Character:WaitForChild("Humanoid").FloorMaterial == Enum.Material.Air then 
				errorNotification('PlayerTP', 'Recall ability not available.', 7)
				return 
			end
			if not bedwars.AbilityController:canUseAbility('recall') then 
				errorNotification('PlayerTP', 'Recall ability not available.', 7)
				return
			end
			pcall(function()
				oldmovefunc = require(lplr.PlayerScripts.PlayerModule).controls.moveFunction 
				require(lplr.PlayerScripts.PlayerModule).controls.moveFunction = function() end
			end)
			bedwars.AbilityController:useAbility('recall')
			local teleported
			PlayerTP:Clean(lplr:GetAttributeChangedSignal('LastTeleported'):Connect(function() teleported = true end))
			repeat task.wait() until teleported or not PlayerTP.Enabled or not isAlive(lplr, true) 
			task.wait()
			local target = GetTarget(nil, PlayerTPSort.Value == 'Health', true)
			if target.RootPart == nil or not isAlive(lplr, true) or not PlayerTP.Enabled then 
				return
			end
			local localposition = lplr.Character:WaitForChild("HumanoidRootPart").Position
			local tweenspeed = (PlayerTPAutoSpeed.Enabled and ((target.RootPart.Position - localposition).Magnitude / 1000) + 0.001 or (PlayerTPSpeed.Value / 1000) + 0.1)
			local tweenstyle = (PlayerTPAutoSpeed.Enabled and Enum.EasingStyle.Linear or Enum.EasingStyle[PlayerTPMethod.Value])
			playertween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(tweenspeed, tweenstyle), {CFrame = target.RootPart.CFrame}) 
			playertween:Play() 
			playertween.Completed:Wait()
		end
	}
	PlayerTP = vape.Categories.Modules:CreateModule({
		Name = 'PlayerTP',
		Tooltip = 'Tweens you to a nearby target.',
		Function = function(calling)
			if calling then 
				task.spawn(function()
					repeat task.wait() until vape.Modules.Invisibility
					repeat task.wait() until vape.Modules.GamingChair
					if vape.Modules.Invisibility.Enabled and vape.Modules.GamingChair.Enabled then
						errorNotification("PlayerTP", "Please turn off the Invisibility and GamingChair module!", 3)
						PlayerTP:Toggle()
						return
					end
					if vape.Modules.Invisibility.Enabled then
						errorNotification("PlayerTP", "Please turn off the Invisibility module!", 3)
						PlayerTP:Toggle()
						return
					end
					if vape.Modules.GamingChair.Enabled then
						errorNotification("PlayerTP", "Please turn off the GamingChair module!", 3)
						PlayerTP:Toggle()
						return
					end
					if GetTarget(nil, PlayerTPSort.Value == 'Health', true) and GetTarget(nil, PlayerTPSort.Value == 'Health', true).RootPart and shared.VapeFullyLoaded then 
						bypassmethods[isAlive() and PlayerTPTeleport.Value or 'Respawn']() 
					else
						InfoNotification("PlayerTP", "No player/s found!", 3)
					end
					if PlayerTP.Enabled then 
						PlayerTP:Toggle()
					end
				end)
			else
				pcall(function() playertween:Disconnect() end)
				if oldmovefunc then 
					pcall(function() require(lplr.PlayerScripts.PlayerModule).controls.moveFunction = oldmovefunc end)
				end
				oldmovefunc = nil
			end
		end
	})
	PlayerTPTeleport = PlayerTP:CreateDropdown({
		Name = 'Teleport Method',
		List = {'Respawn', 'Recall'},
		Function = function() end
	})
	PlayerTPAutoSpeed = PlayerTP:CreateToggle({
		Name = 'Auto Speed',
		Tooltip = 'Automatically uses a "good" tween speed.',
		Default = true,
		Function = function(calling) 
			if calling then 
				pcall(function() PlayerTPSpeed.Object.Visible = false end) 
			else 
				pcall(function() PlayerTPSpeed.Object.Visible = true end) 
			end
		end
	})
	PlayerTPSpeed = PlayerTP:CreateSlider({
		Name = 'Tween Speed',
		Min = 20, 
		Max = 350,
		Default = 200,
		Function = function() end
	})
	PlayerTPMethod = PlayerTP:CreateDropdown({
		Name = 'Teleport Method',
		List = GetEnumItems('EasingStyle'),
		Function = function() end
	})
	PlayerTPSpeed.Object.Visible = false
end)

local GodMode = {Enabled = false}
run(function()
    local antiDeath = {}
    local antiDeathConfig = {
        Mode = {},
        BoostMode = {},
        SongId = {},
        Health = {},
        Velocity = {},
        CFrame = {},
        TweenPower = {},
        TweenDuration = {},
        SkyPosition = {},
        AutoDisable = {},
        Sound = {},
        Notify = {}
    }
    local antiDeathState = {}
    local handlers = {}

    function handlers.new()
        local self = {
			godmode = false,
            boost = false,
            inf = false,
            notify = false,
            id = false,
            hrp = entitylib.character.HumanoidRootPart,
            hasNotified = false
        }
        setmetatable(self, { __index = handlers })
        return self
    end

    function handlers:enable()
		antiDeath:Clean(runService.Heartbeat:Connect(function()
			if not isAlive(lplr, true) then
                handlers:disable()
                return
            end

            if getHealth() <= antiDeathConfig.Health.Value and getHealth() > 0 then
                if not handlers.boost then
                    handlers:activateMode()
                    if not shandlers.hasNotified and antiDeathConfig.Notify.Enabled then
                        handlers:sendNotification()
                    end
                    handlers:playNotificationSound()
                    handlers.boost = true
                end
            else
                handlers:resetMode()
				pcall(function()
					handlers.hrp = entitylib.character.HumanoidRootPart
					handlers.hrp.Anchored = false
				end)
                handlers.boost = false

                if handlers.hasNotified then
                    handlers.hasNotified = false
                end
            end
		end))
    end

    function handlers:disable()
        --RunLoops:UnbindFromHeartbeat('antiDeath')
    end

    function handlers:activateMode()
        local modeActions = {
            Infinite = function() self:enableInfiniteMode() end,
            Boost = function() self:applyBoost() end,
            Sky = function() self:moveToSky() end,
			AntiHit = function() self:enableAntiHitMode() end
        }
        modeActions[antiDeathConfig.Mode.Value]()
    end

	function handlers:enableAntiHitMode()
		if not GodMode.Enabled then
			GodMode:Toggle(false)
			self.godmode = true
		end
	end

    function handlers:enableInfiniteMode()
        if not vape.Modules.InfiniteFly.Enabled then
            vape.Modules.InfiniteFly:Toggle(true)
            self.inf = true
        end
    end

    function handlers:applyBoost()
        local boostActions = {
            Velocity = function() self.hrp.Velocity += Vector3.new(0, antiDeathConfig.Velocity.Value, 0) end,
            CFrame = function() self.hrp.CFrame += Vector3.new(0, antiDeathConfig.CFrame.Value, 0) end,
            Tween = function()
                tweenService:Create(self.hrp, twinfo(antiDeathConfig.TweenDuration.Value / 10), {
                    CFrame = self.hrp.CFrame + Vector3.new(0, antiDeathConfig.TweenPower.Value, 0)
                }):Play()
            end
        }
        boostActions[antiDeathConfig.BoostMode.Value]()
    end

    function handlers:moveToSky()
        self.hrp.CFrame += Vector3.new(0, antiDeathConfig.SkyPosition.Value, 0)
        self.hrp.Anchored = true
    end

    function handlers:sendNotification()
        InfoNotification('AntiDeath', 'Prevented death. Health is lower than ' .. antiDeathConfig.Health.Value ..
            '. (Current health: ' .. math.floor(getHealth() + 0.5) .. ')', 5)
        self.hasNotified = true
    end

    function handlers:playNotificationSound()
        if antiDeathConfig.Sound.Enabled then
            local soundId = antiDeathConfig.SongId.Value ~= '' and antiDeathConfig.SongId.Value or '7396762708'
            playSound(soundId, false)
        end
    end

    function handlers:resetMode()
        if self.inf then
            if antiDeathConfig.AutoDisable.Enabled then
                if vape.Modules.InfiniteFly.Enabled then
                    vape.Modules.InfiniteFly:Toggle(false)
                end
            end
            self.inf = false
            self.hasNotified = false
        elseif self.godmode then
			if antiDeathConfig.AutoDisable.Enabled then
                if GodMode.Enabled then
                    GodMode:Toggle(false)
                end
            end
            self.godmode = false
            self.hasNotified = false
		end
    end

    local antiDeathStatus = handlers.new()

    antiDeath = vape.Categories.Modules:CreateModule({
        Name = 'AntiDeath',
        Function = function(callback)
            if callback then
                coroutine.wrap(function()
                    antiDeathStatus:enable()
                end)()
            else
                pcall(function()
                    antiDeathStatus:disable()
                end)
            end
        end,
        Default = false,
        Tooltip = btext('Prevents you from dying.'),
        ExtraText = function()
            return antiDeathConfig.Mode.Value
        end
    })

    antiDeathConfig.Mode = antiDeath:CreateDropdown({
        Name = 'Mode',
        List = {'Infinite', 'Boost', 'Sky', 'AntiHit'},
        Default = 'AntiHit',
        Tooltip = btext('Mode to prevent death.'),
        Function = function(val)
            antiDeathConfig.BoostMode.Object.Visible = val == 'Boost'
            antiDeathConfig.SkyPosition.Object.Visible = val == 'Sky'
            antiDeathConfig.AutoDisable.Object.Visible = (val == 'Infinite' or val == 'AntiHit')
            antiDeathConfig.Velocity.Object.Visible = false
            antiDeathConfig.CFrame.Object.Visible = false
            antiDeathConfig.TweenPower.Object.Visible = false
            antiDeathConfig.TweenDuration.Object.Visible = false
        end
    })

    antiDeathConfig.BoostMode = antiDeath:CreateDropdown({
        Name = 'Boost',
        List = { 'Velocity', 'CFrame', 'Tween' },
        Default = 'Velocity',
        Tooltip = btext('Mode to boost your character.'),
        Function = function(val)
            antiDeathConfig.Velocity.Object.Visible = val == 'Velocity'
            antiDeathConfig.CFrame.Object.Visible = val == 'CFrame'
            antiDeathConfig.TweenPower.Object.Visible = val == 'Tween'
            antiDeathConfig.TweenDuration.Object.Visible = val == 'Tween'
        end
    })
    antiDeathConfig.BoostMode.Object.Visible = false

    antiDeathConfig.SongId = antiDeath:CreateTextBox({
        Name = 'SongID',
        TempText = 'Song ID',
        Tooltip = 'ID to play the song.',
        FocusLost = function()
            if antiDeath.Enabled then
                antiDeath:Toggle()
                antiDeath:Toggle()
            end
        end
    })
    antiDeathConfig.SongId.Object.Visible = false

    antiDeathConfig.Health = antiDeath:CreateSlider({
        Name = 'Health Trigger',
        Min = 10,
        Max = 90,
        Tooltip = btext('Health at which AntiDeath will perform its actions.'),
        Default = 50,
        Function = function(val) end
    })

    antiDeathConfig.Velocity = antiDeath:CreateSlider({
        Name = 'Velocity Boost',
        Min = 100,
        Max = 600,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 600,
        Function = function(val) end
    })
    antiDeathConfig.Velocity.Object.Visible = false

    antiDeathConfig.CFrame = antiDeath:CreateSlider({
        Name = 'CFrame Boost',
        Min = 100,
        Max = 1000,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.CFrame.Object.Visible = false

    antiDeathConfig.TweenPower = antiDeath:CreateSlider({
        Name = 'Tween Boost',
        Min = 100,
        Max = 1300,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.TweenPower.Object.Visible = false

    antiDeathConfig.TweenDuration = antiDeath:CreateSlider({
        Name = 'Tween Duration',
        Min = 1,
        Max = 10,
        Tooltip = btext('Duration of the tweening process.'),
        Default = 4,
        Function = function(val) end
    })
    antiDeathConfig.TweenDuration.Object.Visible = false

    antiDeathConfig.SkyPosition = antiDeath:CreateSlider({
        Name = 'Sky Position',
        Min = 100,
        Max = 1000,
        Tooltip = btext('Position to TP in the sky.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.SkyPosition.Object.Visible = false

    antiDeathConfig.AutoDisable = antiDeath:CreateToggle({
        Name = 'Auto Disable',
        Tooltip = btext('Automatically disables InfiniteFly after healing.'),
        Function = function(val) end,
        Default = true
    })
    antiDeathConfig.AutoDisable.Object.Visible = false

    antiDeathConfig.Sound = antiDeath:CreateToggle({
        Name = 'Sound',
        Tooltip = btext('Plays a sound after preventing death.'),
        Function = function(callback)
            antiDeathConfig.SongId.Object.Visible = callback
        end,
        Default = true
    })

    antiDeathConfig.Notify = antiDeath:CreateToggle({
        Name = 'Notification',
        Tooltip = btext('Notifies you when AntiDeath actioned.'),
        Default = true,
        Function = function(callback) end
    })
end)

run(function()
	function IsAlive(plr)
		plr = plr or lplr
		if not plr.Character then return false end
		if not plr.Character:FindFirstChild("Head") then return false end
		if not plr.Character:FindFirstChild("Humanoid") then return false end
		if plr.Character:FindFirstChild("Humanoid").Health < 0.11 then return false end
		return true
	end
	local Slowmode = {Value = 2}
	GodMode = vape.Categories.Modules:CreateModule({
		Name = "AntiHit",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait()
						local res, msg = pcall(function()
							if (not vape.Modules.Fly.Enabled) and (not vape.Modules.InfiniteFly.Enabled) then
								for i, v in pairs(game:GetService("Players"):GetChildren()) do
									if v.Team ~= lplr.Team and IsAlive(v) and IsAlive(lplr) then
										if v and v ~= lplr then
											local TargetDistance = lplr:DistanceFromCharacter(v.Character:FindFirstChild("HumanoidRootPart").CFrame.p)
											if TargetDistance < 25 then
												if not lplr.Character:WaitForChild("HumanoidRootPart"):FindFirstChildOfClass("BodyVelocity") then
													repeat task.wait() until store.matchState ~= 0
													if not (v.Character.HumanoidRootPart.Velocity.Y < -10*5) then
														lplr.Character.Archivable = true
				
														local Clone = lplr.Character:Clone()
														Clone.Parent = game.Workspace
														Clone.Head:ClearAllChildren()
														gameCamera.CameraSubject = Clone:FindFirstChild("Humanoid")
					
														for i,v in pairs(Clone:GetChildren()) do
															if string.lower(v.ClassName):find("part") and v.Name ~= "HumanoidRootPart" then
																v.Transparency = 1
															end
															if v:IsA("Accessory") then
																v:FindFirstChild("Handle").Transparency = 1
															end
														end
					
														lplr.Character:WaitForChild("HumanoidRootPart").CFrame = lplr.Character:WaitForChild("HumanoidRootPart").CFrame + Vector3.new(0,100000,0)
					
														GodMode:Clean(game:GetService("RunService").RenderStepped:Connect(function()
															if Clone ~= nil and Clone:FindFirstChild("HumanoidRootPart") then
																Clone.HumanoidRootPart.Position = Vector3.new(lplr.Character:WaitForChild("HumanoidRootPart").Position.X, Clone.HumanoidRootPart.Position.Y, lplr.Character:WaitForChild("HumanoidRootPart").Position.Z)
															end
														end))
					
														task.wait(Slowmode.Value/10)
														lplr.Character:WaitForChild("HumanoidRootPart").Velocity = Vector3.new(lplr.Character:WaitForChild("HumanoidRootPart").Velocity.X, -1, lplr.Character:WaitForChild("HumanoidRootPart").Velocity.Z)
														lplr.Character:WaitForChild("HumanoidRootPart").CFrame = Clone.HumanoidRootPart.CFrame
														gameCamera.CameraSubject = lplr.Character:FindFirstChild("Humanoid")
														Clone:Destroy()
														task.wait(0.15)
													end
												end
											end
										end
									end
								end
							end
						end)
						if not res then warn(msg) end
					until (not GodMode.Enabled)
				end)
			end
		end
	})
	Slowmode = GodMode:CreateSlider({
		Name = "Slowmode",
		Function = function() end,
		Default = 2,
		Min = 1,
		Max = 10
	})
end)

run(function()
    local InfiniteJump
    local Velocity
    InfiniteJump = vape.Categories.Modules:CreateModule({
        Name = "InfiniteJump",
        Function = function(callback)
            if callback then
                local UserInputService = game:GetService("UserInputService")
                local player = playersService.LocalPlayer
                local function setupInfiniteJump()
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    InfiniteJump:Clean(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
                            while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
                                humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, Velocity.Value, humanoidRootPart.Velocity.Z)
                                wait()
                            end
                        end
                    end))
					if UserInputService.TouchEnabled then
						local Jumping = false
						local JumpButton: ImageButton = lplr.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
						
						InfiniteJump:Clean(JumpButton.MouseButton1Down:Connect(function()
							Jumping = true
						end))

						InfiniteJump:Clean(JumpButton.MouseButton1Up:Connect(function()
							Jumping = false
						end))

						InfiniteJump:Clean(runService.RenderStepped:Connect(function()
							if Jumping then
								humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, Velocity.Value, humanoidRootPart.Velocity.Z)
							end
						end))
					end
                end
                player.CharacterAdded:Connect(setupInfiniteJump)
                if player.Character then
                    setupInfiniteJump()
                end
            end
        end,
        Tooltip = "Allows infinite jumping"
    })
    Velocity = InfiniteJump:CreateSlider({
        Name = 'Velocity',
        Min = 50,
        Max = 300,
        Default = 50
    })

	local DeathTPEnabled = false

    local BedTP
    BedTP = vape.Categories.Modules:CreateModule({
        Name = "BedTP",
        Description = "Teleports to enemy beds",
        Function = function(callback)
            if callback then
                BedTP:Toggle(false)
                local collection = game:GetService('CollectionService') :: CollectionService;
                local lplr = playersService.LocalPlayer;
                local tween = game:GetService('TweenService') :: TweenService

                local isshield = function(obj: Model)
                    return obj:GetAttribute('BedShieldEndTime') and obj:GetAttribute('BedShieldEndTime') > workspace:GetServerTimeNow() 
                end
                local getbed = function()
                    for i: number, v: Model? in collection:GetTagged('bed') do
                        if not isshield(v) and v.Bed.BrickColor ~= lplr.TeamColor then
                            return v;
                        end;
                    end;
                end;
                
                local bed = getbed();
                assert(bed, 'lmao');
				local lastDeathTPEnabled = DeathTPEnabled
                pcall(function()
					DeathTPEnabled = false
                    lplr.Character.Humanoid.Health = 0
                end)
                local con;
                con = lplr.CharacterAdded:Connect(function(v)
                    con:Disconnect();
                    task.wait(0.2)
                    tween:Create(v.PrimaryPart, TweenInfo.new(1.35), {CFrame = bed.Bed.CFrame + Vector3.new(0, 20, 0)}):Play();
					DeathTPEnabled = lastDeathTPEnabled
                end);
            end
        end
    })

    local PlayerTP
    PlayerTP = vape.Categories.Modules:CreateModule({
        Name = "PlayerTP",
        Description = "Teleports you to the nearest player",
        Function = function(callback)
            if callback then
                PlayerTP:Toggle(false)
                local Players = game:GetService("Players")
                local TweenService = game:GetService("TweenService")
                local LocalPlayer = playersService.LocalPlayer
                
                local getClosestEnemy = function()
                    local closestPlayer = nil
                    local closestDistance = math.huge
                
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.TeamColor ~= LocalPlayer.TeamColor and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                
                    return closestPlayer
                end
                
                local targetPlayer = getClosestEnemy()
                assert(targetPlayer, "No enemy players found!")
                
				local lastDeathTPEnabled = DeathTPEnabled
                pcall(function()
					DeathTPEnabled = false
                    LocalPlayer.Character.Humanoid.Health = 0
                end)
                
                local connection
                connection = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
                    connection:Disconnect()
                    task.wait(0.2)
                
                    local targetPosition = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                    tweenService:Create(newCharacter.PrimaryPart, TweenInfo.new(0.75), {CFrame = targetPosition}):Play()
					DeathTPEnabled = lastDeathTPEnabled
                end)
            end
        end
    })

	local DeathTP
	local LastPos = nil
	DeathTP = vape.Categories.Modules:CreateModule({
        Name = "DeathTP",
        Description = "Teleports you to the lastest death position",
        Function = function(callback)
            DeathTPEnabled = callback
        end
    })
	local function setupEvent(char)
		task.wait(0.2)
		if DeathTPEnabled and LastPos and LastPos.Y > 20 then
			tweenService:Create(char.PrimaryPart, TweenInfo.new(0.75), {CFrame = LastPos}):Play()
		end
		if char:FindFirstChildOfClass("Humanoid") then
			DeathTP:Clean(char:FindFirstChildOfClass("Humanoid").Died:Once(function()
				LastPos = char.PrimaryPart and char.PrimaryPart.CFrame or nil
			end))
		end
	end
	DeathTP:Clean(lplr.CharacterAdded:Connect(setupEvent))
	if lplr.Character then
		setupEvent(lplr.Character)
	end
end)


run(function()
	local Autowin = {Enabled = false}
	local AutowinNotification = {Enabled = true}
	local bedtween
	local playertween
	Autowin = vape.Categories.Modules:CreateModule({
		Name = "Autowin",
		ExtraText = function() return store.queueType:find("5v5") and "BedShield" or "Normal" end,
		Function = function(callback)
			if callback then
				task.spawn(function()
					if store.matchState == 0 then repeat task.wait() until store.matchState ~= 0 or not Autowin.Enabled end
					if not Autowin.Enabled then return end
					vapeAssert(not store.queueType:find("skywars"), "Autowin", "Skywars not supported.", 7, true, true, "Autowin")
					if isAlive(lplr, true) then
						lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
						lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
					end
					Autowin:Clean(runService.Heartbeat:Connect(function()
						pcall(function()
							if not isnetworkowner(lplr.Character:FindFirstChild("HumanoidRootPart")) and (FindEnemyBed() and GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), FindEnemyBed()) > 75 or not FindEnemyBed()) then
								if isAlive(lplr, true) and FindTeamBed() and Autowin.Enabled and (not store.matchState == 2) then
									lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
									lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
								end
							end
						end)
					end))
					Autowin:Clean(lplr.CharacterAdded:Connect(function()
						if not isAlive(lplr, true) then repeat task.wait() until isAlive(lplr, true) end
						local bed = FindEnemyBed()
						if bed and (bed:GetAttribute("BedShieldEndTime") and bed:GetAttribute("BedShieldEndTime") < workspace:GetServerTimeNow() or not bed:GetAttribute("BedShieldEndTime")) then
						bedtween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(0.65, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0), {CFrame = CFrame.new(bed.Position) + Vector3.new(0, 10, 0)})
						task.wait(0.1)
						bedtween:Play()
						bedtween.Completed:Wait()
						task.spawn(function()
						task.wait(1.5)
						local magnitude = GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), bed)
						if magnitude >= 50 and FindTeamBed() and Autowin.Enabled then
							lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
							lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
						end
						end)
						if AutowinNotification.Enabled then
							local bedname = XStore.bedtable[bed] or "unknown"
							task.spawn(InfoNotification, "Autowin", "Destroying "..bedname:lower().." team's bed", 5)
						end
						repeat task.wait() until FindEnemyBed() ~= bed or not isAlive()
						if FindTarget(45, store.blockRaycast) and FindTarget(45, store.blockRaycast).RootPart and isAlive() then
							if AutowinNotification.Enabled then
								local team = XStore.bedtable[bed] or "unknown"
								task.spawn(InfoNotification, "Autowin", "Killing "..team:lower().." team's teamates", 5)
							end
							repeat
							local target = FindTarget(45, store.blockRaycast)
							if not target.RootPart then break end
							playertween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(0.65), {CFrame = target.RootPart.CFrame + Vector3.new(0, 3, 0)})
							playertween:Play()
							task.wait()
							until not (FindTarget(45, store.blockRaycast) and FindTarget(45, store.blockRaycast).RootPart) or not Autowin.Enabled or not isAlive()
						end
						if isAlive(lplr, true) and FindTeamBed() and Autowin.Enabled then
							lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
							lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
						end
						elseif FindTarget(nil, store.blockRaycast) and FindTarget(nil, store.blockRaycast).RootPart then
							task.wait()
							local target = FindTarget(nil, store.blockRaycast)
							playertween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(0.65, Enum.EasingStyle.Linear), {CFrame = target.RootPart.CFrame + Vector3.new(0, 3, 0)})
							playertween:Play()
							if AutowinNotification.Enabled then
								task.spawn(InfoNotification, "Autowin", "Killing "..target.Player.DisplayName.." ("..(target.Player.Team and target.Player.Team.Name or "neutral").." Team)", 5)
							end
							playertween.Completed:Wait()
							if not Autowin.Enabled then return end
								if FindTarget(50, store.blockRaycast).RootPart and isAlive() then
									repeat
									target = FindTarget(50, store.blockRaycast)
									if not target.RootPart or not isAlive() then break end
									playertween = tweenService:Create(lplr.Character:WaitForChild("HumanoidRootPart"), TweenInfo.new(0.65), {CFrame = target.RootPart.CFrame + Vector3.new(0, 3, 0)})
									playertween:Play()
									task.wait()
									until not (FindTarget(50, store.blockRaycast) and FindTarget(50, store.blockRaycast).RootPart) or (not Autowin.Enabled) or (not isAlive())
								end
							if isAlive(lplr, true) and FindTeamBed() and Autowin.Enabled then
								lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
								lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
							end
						else
						if store.matchState == 2 then return end
						lplr.Character:WaitForChild("Humanoid"):TakeDamage(lplr.Character:WaitForChild("Humanoid").Health)
						lplr.Character:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
						end
					end))
					Autowin:Clean(lplr.CharacterAdded:Connect(function()
						if (not isAlive(lplr, true)) then repeat task.wait() until isAlive(lplr, true) end
						if (not store.matchState == 2) then return end
						--[[local oldpos = lplr.Character:WaitForChild("HumanoidRootPart").CFrame
						repeat 
							lplr.Character:WaitForChild("HumanoidRootPart").CFrame = oldpos
							task.wait()
						until (not isAlive(lplr, true)) or (not Autowin.Enabled)--]]
					end))
				end)
			else
				pcall(function() playertween:Cancel() end)
				pcall(function() bedtween:Cancel() end)
			end
		end,
		HoverText = "best paid autowin 2023!1!!! rel11!11!1"
	})
end)

run(function()
	local GetHost = {Enabled = false}
	GetHost = vape.Categories.Modules:CreateModule({
		Name = "GetHost",
		Tooltip = ":troll:",
		Function = function(callback) 
			if callback then
				task.spawn(function()
					warningNotification("GetHost", "This module is only for show. None of the settings will work.", 5)
					game.Players.LocalPlayer:SetAttribute("CustomMatchRole", "host")
				end)
			end
		end
	})
end)

run(function()
    local NightmareEventButton
    NightmareEventButton = vape.Categories.Modules:CreateModule({
        Name = "Nightmare Emote",
        Description = "Play Nightmare Emote",
        Function = function(callback)
            if callback then
                NightmareEventButton:Toggle(false)
                activateNightmareEmote()
            end
        end
    })

    local pack1
	local packassetids = {
		['1024x Pack'] = 'rbxassetid://14078540433',
		['CottanCandy256x'] = 'rbxassetid://14161283331',
		['512x Pack'] = 'rbxassetid://14224565815',
		['Beloved E-Girl Pack'] = 'rbxassetid://14126814481',
		['GLIZZZYYYYY'] = 'rbxassetid://13804645310',
		['RandomPack1'] = 'rbxassetid://13783192680',
		['RandomPack2'] = 'rbxassetid://13801616054',
		['RandomPack3'] = '',
		['RandomPack4'] = 'rbxassetid://13801509384',
		['RandomPack5'] = 'rbxassetid://13802020264',
		['RandomPack6'] = 'rbxassetid://13780890894',
		['RandomPack7'] = 'rbxassetid://14033898270',
		['DemonSlayer Pack'] = 'rbxassetid://14241215869',
		['Exhibition Pack'] = 'rbxassetid://14060102755',
		['Vibe Pack'] = 'rbxassetid://14282106674',
		['MainPack'] = 'rbxassetid://79898012794679'
	}
    local TexturePacks 
	TexturePacks = vape.Categories.Modules:CreateModule({
        Name = 'TexturePacks',
        Tooltip = 'Gives you a cool unique textures for tools.',
        Function = function(call)
            if call then
				local import = game:GetObjects(packassetids[pack1.Value])[1]
				import.Parent = replicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
				}
				for i,v in {'Wood', 'Diamond', 'Emerald', 'Stone', 'Iron', 'Gold'} do
					if import:FindFirstChild(`{v}_Pickaxe`) then
						table.insert(index, {
							name = `{v:lower()}_pickaxe`,
							offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
							model = import[`{v}_Pickaxe`],
						})
					end
					if import:FindFirstChild(v) then
						table.insert(index, {
							name = `{v:lower()}`,
							offset = CFrame.Angles(math.rad(0),math.rad(-90),math.rad(table.find({'Emerald', 'Diamond'}, v) and 90 or -90)),
							model = import[`{v}`],
						})
					end
				end
				TexturePacks:Clean(workspace.Camera.Viewmodel.ChildAdded:Connect(function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = lplr.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end            
							end            
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.6,0,-.9)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end))
            end
        end
    })
	local list = {}
	for i,v in packassetids do
		table.insert(list, i)
	end
    pack1 = TexturePacks:CreateDropdown({
        Name = 'Pack',
        List = list,
		Function = function()
			if TexturePacks.Enabled then
				TexturePacks:Toggle()
				TexturePacks:Toggle()
			end
		end
    })
end)

run(function()
    local Skybox
    GameThemeV2 = vape.Categories.Modules:CreateModule({
        Name = 'GameThemeV2',
        Tooltip = '',
        Function = function(call)
            if call then
                if Skybox.Value == "NebulaSky" then
					local Vignette = true

					local Lighting = game:GetService("Lighting")
					local ColorCor = Instance.new("ColorCorrectionEffect")
					local Sky = Instance.new("Sky")
					local Atm = Instance.new("Atmosphere")
					
					for i, v in pairs(Lighting:GetChildren()) do
						if v then
							v:Destroy()
						end
					end
					
					ColorCor.Parent = Lighting
					Sky.Parent = Lighting
					Atm.Parent = Lighting
					
					if Vignette == true then
						local Gui = Instance.new("ScreenGui")
						Gui.Parent = game:GetService("StarterGui")
						Gui.IgnoreGuiInset = true
					
						local ShadowFrame = Instance.new("ImageLabel")
						ShadowFrame.Parent = Gui
						ShadowFrame.AnchorPoint = Vector2.new(0, 1)
						ShadowFrame.Position = UDim2.new(0, 0, 0, 0)
						ShadowFrame.Size = UDim2.new(0, 0, 0, 0)
						ShadowFrame.BackgroundTransparency = 1
						ShadowFrame.Image = ""
						ShadowFrame.ImageTransparency = 1
						ShadowFrame.ZIndex = 0
					end
					
					ColorCor.Brightness = 0
					ColorCor.Contrast = 0.5
					ColorCor.Saturation = -0.3
					ColorCor.TintColor = Color3.fromRGB(255, 235, 203)
					
					Sky.SkyboxBk = "rbxassetid://13581437029"
					Sky.SkyboxDn = "rbxassetid://13581439832"
					Sky.SkyboxFt = "rbxassetid://13581447312"
					Sky.SkyboxLf = "rbxassetid://13581443463"
					Sky.SkyboxRt = "rbxassetid://13581452875"
					Sky.SkyboxUp = "rbxassetid://13581450222"
					Sky.SunAngularSize = 0
					
					Lighting.Ambient = Color3.fromRGB(2, 2, 2)
					Lighting.Brightness = 1
					Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
					Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
					Lighting.EnvironmentDiffuseScale = 0.2
					Lighting.EnvironmentSpecularScale = 0.2
					Lighting.GlobalShadows = true
					Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
					Lighting.ShadowSoftness = 0.2
					Lighting.ClockTime = 8
					Lighting.GeographicLatitude = 45
					Lighting.ExposureCompensation = 0.5
					
					Atm.Density = 0.364
					Atm.Offset = 0.556
					Atm.Color = Color3.fromRGB(172, 120, 186)
					Atm.Decay = Color3.fromRGB(155, 212, 255)
					Atm.Glare = 0.36
					Atm.Haze = 1.72					
                elseif Skybox.Value == "PinkMountainSky" then
					game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=160188495"
					game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=160188614"
					game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=160188609"
					game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=160188589"
					game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=160188597"
					game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=160188588"
				elseif Skybox.Value == "PurpleSky" then
					game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=570557514"
					game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=570557775"
					game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=570557559"
					game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=570557620"
					game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=570557672"
					game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=570557727"
					game.Lighting.ColorCorrectionEffect.Saturation = 0.7
					game.Lighting.ColorCorrectionEffect.Brightness = -0.02					
                elseif Skybox.Value == "CitySky" then

					local Vignette = true

					local Lighting = game:GetService("Lighting")
					local ColorCor = Instance.new("ColorCorrectionEffect")
					local Sky = Instance.new("Sky")
					local Atm = Instance.new("Atmosphere")

					game.Lighting.Sky.SkyboxBk = "rbxassetid://11263062161"
					game.Lighting.Sky.SkyboxDn = "rbxassetid://11263065295"
					game.Lighting.Sky.SkyboxFt = "rbxassetid://11263066644"
					game.Lighting.Sky.SkyboxLf = "rbxassetid://11263068413"
					game.Lighting.Sky.SkyboxRt = "rbxassetid://11263069782"
					game.Lighting.Sky.SkyboxUp = "rbxassetid://11263070890"

					Atm.Density = 0.364
					Atm.Offset = 0.556
					Atm.Color = Color3.fromRGB(172, 120, 186)
					Atm.Decay = Color3.fromRGB(155, 212, 255)
					Atm.Glare = 0.36
					Atm.Haze = 1.72		
                elseif Skybox.Value == "PinkSky" then
					game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=271042516"
					game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=271077243"
					game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=271042556"
					game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=271042310"
					game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=271042467"
					game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=271077958"
                elseif Skybox.Value == "EgirlSky" then
					game.Lighting.Sky.SkyboxBk = "rbxassetid://2128458653"
					game.Lighting.Sky.SkyboxDn = "rbxassetid://2128462480"
					game.Lighting.Sky.SkyboxFt = "rbxassetid://2128458653"
					game.Lighting.Sky.SkyboxLf = "rbxassetid://2128462027"
					game.Lighting.Sky.SkyboxRt = "rbxassetid://2128462027"
					game.Lighting.Sky.SkyboxUp = "rbxassetid://2128462236"
					game.Lighting.sky.SunAngularSize = 4
					game.Lighting.sky.MoonTextureId = "rbxassetid://8139665943"
					game.Lighting.sky.MoonAngularSize = 11
					lightingService.Atmosphere.Color = Color3.fromRGB(255, 214, 172)
					lightingService.Atmosphere.Decay = Color3.fromRGB(255, 202, 175)
                elseif Skybox.Value == "SpaceSky" then
					game.Lighting.Sky.SkyboxBk = "rbxassetid://1735468027"
					game.Lighting.Sky.SkyboxDn = "rbxassetid://1735500192"
					game.Lighting.Sky.SkyboxFt = "rbxassetid://1735467260"
					game.Lighting.Sky.SkyboxLf = "rbxassetid://1735467682"
					game.Lighting.Sky.SkyboxRt = "rbxassetid://1735466772"
					game.Lighting.Sky.SkyboxUp = "rbxassetid://1735500898"
				elseif Skybox.Value == "WhiteMountains" then 
					local Vignette = true
					local Lighting = game:GetService("Lighting")
					local ColorCor = Instance.new("ColorCorrectionEffect")
					local SunRays = Instance.new("SunRaysEffect")
					local Sky = Instance.new("Sky")
					local Atm = Instance.new("Atmosphere")
					game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=14365017479"
					game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=14365021997"
					game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=14365016611"
					game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=14365016884"
					game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=14365016261"
					game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=14365017884"
					

					Lighting.Ambient = Color3.fromRGB(2,2,2)
					Lighting.Brightness = 0.3
					Lighting.EnvironmentDiffuseScale = 0.2
					Lighting.EnvironmentSpecularScale = 0.2
					Lighting.GlobalShadows = true
					Lighting.ShadowSoftness = 0.2
					Lighting.ClockTime = 15
					Lighting.GeographicLatitude = 45
					Lighting.ExposureCompensation = 0.5
					Atm.Density = 0.364
					Atm.Offset = 0.556
					Atm.Glare = 0.36
					Atm.Haze = 1.72
                elseif Skybox.Value == "Infinite" then
					game.Lighting.Sky.SkyboxBk = "rbxassetid://14358449723"
					game.Lighting.Sky.SkyboxDn = "rbxassetid://14358455642"
					game.Lighting.Sky.SkyboxFt = "rbxassetid://14358452362"
					game.Lighting.Sky.SkyboxLf = "rbxassetid://14358784700"
					game.Lighting.Sky.SkyboxRt = "rbxassetid://14358454172"
					game.Lighting.Sky.SkyboxUp = "rbxassetid://14358455112"
                end
            end
        end
    })
    Skybox = GameThemeV2:CreateDropdown({
        Name = 'Themes',
        List = {'NebulaSky', "PinkMountainSky", 
		"CitySky", "PinkSky", 
		"EgirlSky", "SpaceSky", "WhiteMountains",
		"Infinite", "PurpleSky"},
        ["Function"] = function() end
    })
end)

run(function()
    local AdetundeExploit
    local AdetundeExploit_List

    local adetunde_remotes = {
        ["Shield"] = function()
            local args = { [1] = "shield" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Speed"] = function()
            local args = { [1] = "speed" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Strength"] = function()
            local args = { [1] = "strength" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end
    }

    local current_upgrador = "Shield"
    local hasnt_upgraded_everything = true
    local testing = 1

    AdetundeExploit = vape.Categories.Modules:CreateModule({
        Name = 'AdetundeExploit',
        Function = function(calling)
            if calling then 
                -- Check if in testing mode or equipped kit
                -- if tostring(shared.store.queueType) == "training_room" or shared.store.equippedKit == "adetunde" then
                --     AdetundeExploit["ToggleButton"](false) 
                --     current_upgrador = AdetundeExploit_List.Value
                task.spawn(function()
                    repeat
                        local returning_table = adetunde_remotes[current_upgrador]()
                        
                        if type(returning_table) == "table" then
                            local Speed = returning_table["speed"]
                            local Strength = returning_table["strength"]
                            local Shield = returning_table["shield"]

                            print("Speed: " .. tostring(Speed))
                            print("Strength: " .. tostring(Strength))
                            print("Shield: " .. tostring(Shield))
                            print("Current Upgrador: " .. tostring(current_upgrador))

                            if returning_table[string.lower(current_upgrador)] == 3 then
                                if Strength and Shield and Speed then
                                    if Strength == 3 or Speed == 3 or Shield == 3 then
                                        if (Strength == 3 and Speed == 2 and Shield == 2) or
                                           (Strength == 2 and Speed == 3 and Shield == 2) or
                                           (Strength == 2 and Speed == 2 and Shield == 3) then
                                            -- warningNotification("AdetundeExploit", "Fully upgraded everything possible!", 7)
                                            hasnt_upgraded_everything = false
                                        else
                                            local things = {}
                                            for i, v in pairs(adetunde_remotes) do
                                                table.insert(things, i)
                                            end
                                            for i, v in pairs(things) do
                                                if things[i] == current_upgrador then
                                                    table.remove(things, i)
                                                end
                                            end
                                            local random = things[math.random(1, #things)]
                                            current_upgrador = random
                                        end
                                    end
                                end
                            end
                        else
                            local things = {}
                            for i, v in pairs(adetunde_remotes) do
                                table.insert(things, i)
                            end
                            for i, v in pairs(things) do
                                if things[i] == current_upgrador then
                                    table.remove(things, i)
                                end
                            end
                            local random = things[math.random(1, #things)]
                            current_upgrador = random
                        end
                        task.wait(0.1)
                    until not AdetundeExploit.Enabled or not hasnt_upgraded_everything
                end)
                -- else
                --     AdetundeExploit["ToggleButton"](false)
                --     warningNotification("AdetundeExploit", "Kit required or you need to be in testing mode", 5)
                -- end
            end
        end
    })

    local real_list = {}
    for i, v in pairs(adetunde_remotes) do
        table.insert(real_list, i)
    end

    AdetundeExploit_List = AdetundeExploit:CreateDropdown({
        Name = 'Preferred Upgrade',
        List = real_list,
        Function = function() end,
        Default = "Shield"
    })
end)

run(function()
	local NoNameTag
	NoNameTag = vape.Categories.Modules:CreateModule({
		PerformanceModeBlacklisted = true,
		Name = 'NoNameTag',
        Tooltip = 'Removes your NameTag.',
		Function = function(callback)
			if callback then
				NoNameTag:Clean(runService.RenderStepped:Connect(function()
					pcall(function()
						lplr.Character.Head.Nametag:Destroy()
					end)
				end))
			end
		end,
        Default = false
	})
end)
