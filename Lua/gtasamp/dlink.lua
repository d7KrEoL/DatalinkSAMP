require 'sampfuncs'
require 'samp/events/core'

local inicfg = require "inicfg"
local sampev = require 'lib.samp.events'

local copas = require 'copas'
local http = require 'copas.http'

local lastTransmit = os.clock()

local LongRageMarkers = {playername, isActiveMarker, coords = {x, y, z}}
local AllEnemies = { room, name, objType, pos = {x, y, z}, vec = {x, y, z} }

local vectorSpeedMultiplier = 50
local transmitionInterval = 50

script_name("dlink")
script_author("d7.KrEoL")
script_version("07.12.24-unstable")
script_url("https://vk.com/d7kreol")
script_description("In-game tactical data exchange")


local settings = inicfg.load(
	{
	  maincfg = {
		enableTransmit = false,
		sendSelf = true,
		sendTargets = true,
		sendMarkers = true,
		receiveTargets = true,
		sendAlly = true,
		receiveAlly = true,
		sendEnemies = true,
		receiveEnemies = true,
		sendUnknown = true,
		receiveUnknown = true,
		tickTime = 1,
		maxPlayers = 20,
		serverHost = "datalink.sampmap.ru",
		serverName = "MainServer",
		serverPassword = "changeme",
		userName = "Unnamed",
	  },
	},
	"datalinksa"
)

function main()
	repeat wait(0) until isSampLoaded()
	repeat wait(0) until isSampAvailable()
	initVars()
	while true do
		onUpdate()
		wait(0)
	end
end

function onExitScript(quitGame)
	clearVars("datalink script exit")
end

function initVars()
	sampRegisterChatCommand("dlink", cmdDatalink)
	sampfuncsRegisterConsoleCommand("dlink", cmdDatalink)
end

function clearVars()
	sampUnregisterChatCommand("dlink")
	sampfuncsUnregisterConsoleCommand("dlink")
end

function sampev.onSendCommand(command)
    local cmdParse = split(command, ' ')
	if #cmdParse > 0 then
		if (cmdParse[1] == "/dlink") then 
			cmdDatalink(command) 
			return false
		end
	end
end

function onUpdate()
	if not sampIsLocalPlayerSpawned() then return end
	if not settings.maincfg.enableTransmit then return end
	if os.clock() - lastTransmit < settings.maincfg.tickTime then return end
	onUpdateSelf()
	onUpdateEnemy()
	onUpdateMarkers()
end

function onUpdateSelf()
	if not settings.maincfg.sendSelf then return end
	local posX, posY, posZ = getCharCoordinates(playerPed)
	local vecX = 0
	local vecY = 0
	local vecZ = 0
	
	if isCharInAnyCar(playerPed) then
		local vehicleid = storeCarCharIsInNoSave(playerPed)
		if vehicleid == nil then return end
		vecX, vecY, vecZ = getCarSpeedVector(vehicleid)
	else
		vecX, vecY, vecZ = getCharVelocity(playerPed)
	end
	
	vecX = posX + vecX
	vecY = posY + vecY
	vecZ = posZ + vecZ
				
	local selfData = getSelfData({x = posX, y = posY, z = posZ}, {x = vecX, y = vecY, z = vecZ})

	sendAlly(selfData)
end

function onUpdateEnemy()
	if not settings.maincfg.sendTargets then return end
	sendEnemies()
end

function sendAlly(data)
	httpRequest(string.format("https://%s/tacxally?room=%s&name=%s&objectType=%s&posX=%s&posY=%s&posZ=%s&vecX=%s&vecY=%s&vecZ=%s", 
				settings.maincfg.serverHost,
				data.room,
				data.name, 
				data.objType,
				data.pos.x,
				data.pos.y,
				data.pos.z,
				data.vec.x,
				data.vec.y,
				data.vec.z
				), 
		nil, 
		function(response, code, headers, status)
		
		if not response then
			print("[SEND ALLY] Error: (response:", response, ")")
			print("code: ", code, "headers:", headers, "status:", status)
			print("{FF0000}emergency turn off")
			settings.maincfg.enableTransmit = false
		end
	end)
	lastTransmit = os.clock()
end

function sendEnemies()
	lua_thread.create(function()
		for i = 0, #AllEnemies > settings.maincfg.maxPlayers and maxPlayers or #AllEnemies do
			if AllEnemies[i] ~= nil then
				sendEnemy(AllEnemies[i])
				wait(transmitionInterval)
			end
		end
		ClearEnemiesData()
	end)
end

function sendEnemy(data)
	wait(settings.maincfg.tickTime)
	httpRequest(string.format("https://%s/tacxenemy?room=%s&name=%s&objectType=%s&posX=%s&posY=%s&posZ=%s&vecX=%s&vecY=%s&vecZ=%s", 
				settings.maincfg.serverHost,
				data.room,
				data.name, 
				data.objType,
				data.pos.x,
				data.pos.y,
				data.pos.z,
				data.vec.x,
				data.vec.y,
				data.vec.z
				), 
		nil, 
		function(response, code, headers, status)
		
		if not response then
			print("[SEND ENEMY] Error: (response:", response, ")")
			print("code: ", code, "headers:", headers, "status:", status)
			print("{FF0000}emergency turn off")
			settings.maincfg.enableTransmit = false
		end
	end)
	lastTransmit = os.clock()
end

function sampev.onVehicleSync(playerId, vehicleId, data)
	if settings.maincfg.sendTargets then
		AddEnemiesData({
			room = settings.maincfg.serverName,
			name = sampGetPlayerNickname(playerId),
			objType = 1,
			pos = {x = data.position.x, y = data.position.y, z = data.position.z},
			vec = 
				{
					x = data.position.x + (data.moveSpeed.x * vectorSpeedMultiplier), 
					y = data.position.y + (data.moveSpeed.y * vectorSpeedMultiplier), 
					z = data.position.z + data.moveSpeed.z
				}
		})
	end	
end

function sampev.onPlayerSync(playerId, data)
	if settings.maincfg.sendTargets then

		AddEnemiesData({
			room = settings.maincfg.serverName,
			name = sampGetPlayerNickname(playerId),
			objType = 1,
			pos = {x = data.position.x, y = data.position.y, z = data.position.z},
			vec = 
				{
					x = data.position.x + (data.moveSpeed.x * vectorSpeedMultiplier), 
					y = data.position.y + (data.moveSpeed.y * vectorSpeedMultiplier), 
					z = data.position.z + data.moveSpeed.z
				}
		})
	end	
end

function ClearEnemiesData()
	if (AllEnemies == nil) then return end
	for i = 1, #AllEnemies do
		AllEnemies[i] = nil
	end
end

function AddEnemiesData(data)
	if isEnemiesDataExist(data.name) then return end
	table.insert(AllEnemies, data)
end


function isEnemiesDataExist(playerName)
	if AllEnemies == nil then return end
	if #AllEnemies < 1 then return end
	for i = 0, #AllEnemies do
		if AllEnemies[i] ~= nil then
			if AllEnemies[i].name == playerName then return true end
		end
	end
	return false
end

function sampev.onMarkersSync(markers)
	if settings.maincfg.sendTargets then
		local playerid, isActiveMarker, pos
		ClearMarkersData()
		for i = 1, #markers > settings.maincfg.maxPlayers and maxPlayers or #markers do
			AddMarkersData(markers[i])
		end
	end
end

function ClearMarkersData()
	if (LongRageMarkers == nil) then return end
	for i = 1, #LongRageMarkers do
		LongRageMarkers[i] = nil
	end
end

function AddMarkersData(marker)
	if (LongRageMarkers == nil) then return end
	lua_thread.create(function()
		if marker.active then
			wait(0)
			local playerName = sampGetPlayerNickname(marker.playerId)
			if isEnemiesDataExist(playerName) then return end
			table.insert(LongRageMarkers, 
			{
				playername = playerName, 
				isActiveMarker = marker.active, 
				coords = {x = marker.coords.x, y = marker.coords.y, z = marker.coords.z}
			})
		end
	end)
end

function onUpdateMarkers()
	if (LongRageMarkers == nil) then return end
	if not settings.maincfg.sendMarkers then return end
	if #LongRageMarkers > 0 then
		local packetCounter = 0
		lua_thread.create(onUpdateMarkersTask)
	end
end

function onUpdateMarkersTask()
	wait(10)
	for i = 1, #LongRageMarkers do
		if not(LongRageMarkers[i] == nil) then
			local enemyData =  
				{ 
					room = settings.maincfg.serverName, 
					name = LongRageMarkers[i].playername, 
					objType = 1, 
					pos = {x = LongRageMarkers[i].coords.x, y = LongRageMarkers[i].coords.y, z = LongRageMarkers[i].coords.z}, 
					vec = {x = LongRageMarkers[i].coords.x, y = LongRageMarkers[i].coords.y, z = LongRageMarkers[i].coords.z}
				}
			sendEnemy(enemyData)
		end
	end
end

function getSelfData(position, vector)
	local allyData = { room, name, objType, pos = {x, y, z}, vec = {x, y, z} }
	allyData.room = settings.maincfg.serverName
	allyData.name = sampGetPlayerNickname(playerHandle)
	allyData.objType = 1
	
	allyData.pos.x = position.x
	allyData.pos.y = position.y
	allyData.pos.z = position.z
	
	allyData.vec.x = vector.x
	allyData.vec.y = vector.y
	allyData.vec.z = vector.z

	return allyData
end

function httpRequest(request, body, handler)
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

function split (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end


function cmdDatalink(arg)
	if #arg < 1 then
		print("{FFCC00}Syntax: {FFFFFF}/dlink [setting_name] [value]")
		print("{FFCC00}Example: {FFFFFF}/dlink {999999}serverHost sampmap.ru")
		print("{FFCC00}Example: {FFFFFF}/dlink {999999}sendTargets")
		return
	else
		local args = {}
		for str in string.gmatch(arg, "([^".." ".."]+)") do
			table.insert(args, str)
			print("str:", str)
		end
		
		if (args[1] == "sendSelf") then 
			settings.maincfg.sendSelf = not settings.maincfg.sendSelf
			inicfg.save(settings, "datalinksa")
			print("sendSelf=", settings.maincfg.sendSelf)
		elseif (args[1] == "sendTargets") then 
			settings.maincfg.sendTargets = not settings.maincfg.sendTargets
			inicfg.save(settings, "datalinksa")
			print("sendTargets=", settings.maincfg.sendTargets)
		elseif (args[1] == "sendMarkers") then 
			settings.maincfg.sendMarkers = not settings.maincfg.sendMarkers
			inicfg.save(settings, "datalinksa")
			print("sendMarkers=", settings.maincfg.sendMarkers)
		elseif (args[1] == "receiveTargets") then 
			settings.maincfg.receiveTargets = not settings.maincfg.receiveTargets
			inicfg.save(settings, "datalinksa")
			print("receiveTargets=", settings.maincfg.receiveTargets)
		elseif (args[1] == "sendAlly") then 
			settings.maincfg.sendAlly = not settings.maincfg.sendAlly
			inicfg.save(settings, "datalinksa")
			print("sendAlly=", settings.maincfg.receiveTargets)
		elseif (args[1] == "receiveAlly") then
			settings.maincfg.receiveAlly = not settings.maincfg.receiveAlly
			inicfg.save(settings, "datalinksa")
			print("receiveAlly=", settings.maincfg.receiveAlly)
		elseif (args[1] == "sendEnemy") then 
			settings.maincfg.sendEnemies = not settings.maincfg.sendEnemies
			inicfg.save(settings, "datalinksa")
			print("sendEnemy=", settings.maincfg.sendEnemies)
		elseif (args[1] == "receiveEnemy") then 
			settings.maincfg.receiveEnemies = not settings.maincfg.receiveEnemies
			inicfg.save(settings, "datalinksa")
			print("receiveEnemy=", settings.maincfg.receiveEnemies)
		elseif (args[1] == "sendUnknown") then 
			settings.maincfg.sendUnknown = not settings.maincfg.sendUnknown
			inicfg.save(settings, "datalinksa")
			print("sendUnknown=", settings.maincfg.sendUnknown)
		elseif (args[1] == "receiveUnknown") then 
			settings.maincfg.receiveUnknown = not settings.maincfg.receiveUnknown
			inicfg.save(settings, "datalinksa")
			print("receiveUnknown=", settings.maincfg.receiveUnknown)
		elseif (args[1] == "tickTime") then 
			if (#args < 3) then
				print("tickTime=", settings.maincfg.tickTime)
				return
			end
			settings.maincfg.tickTime = tonumber(args[3])
			if settings.maincfg.tickTime < 1 then settings.maincfg.tickTime = 1 end
			inicfg.save(settings, "datalinksa")
		elseif (args[1] == "maxPlayers") then 
			if (#args < 2) then
				print("maxPlayers=", settings.maincfg.maxPlayers)
				return
			end
			settings.maincfg.maxPlayers = tonumber(args[1])
			if settings.maincfg.maxPlayers < 0 then settings.maincfg.maxPlayers = 1 end
			inicfg.save(settings, "datalinksa")	
		elseif (args[1] == "start" or args[1] == "connect") then 
			print("datalink transmition enabled")
			settings.maincfg.enableTransmit = true
		elseif (args[1] == "stop" or args[1] == "disconnect") then 
			print("datalink transmition disabled")
			settings.maincfg.enableTransmit = false
		elseif (args[1] == "serverHost" or args[1] == "hostURL") then
			if (#args < 2) then 
				print("serverHost=", settings.maincfg.serverHost) 
				return
			end
			settings.maincfg.serverHost = args[2]
			inicfg.save(settings, "datalinksa")
		elseif (args[1] == "serverName") then
			if (#args < 2) then print("serverName=", settings.maincfg.serverName) return end
			settings.maincfg.serverName = args[2]
			inicfg.save(settings, "datalinksa")
		elseif (args[1] == "serverPassword") then
			if (#args < 2) then print("serverPassword=", settings.maincfg.serverPassword) return end
			settings.maincfg.serverPassword = args[2]
			inicfg.save(settings, "datalinksa")
		elseif (args[1] == "userName") then
			if (#args < 2) then print("userName=", settings.maincfg.userName) return end
			settings.maincfg.userName = args[2]
			inicfg.save(settings, "datalinksa")
		elseif (args[1] == "help") then
			print("Datalink commands:")
			print("")
			print("start stop")
			print("enableTransmit sendTargets sendMarkers sendAlly sendEnemy")
			print("receiveEnemy receiveTargets receiveAlly receiveUnknown")
			print("maxPlayers")
			print("serverName serverPassword userName")
			print("")
		else
			print("Unknown datalink command")
		end
	end
end
