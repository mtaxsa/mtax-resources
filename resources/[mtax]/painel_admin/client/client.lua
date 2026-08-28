local _mtax = {};

_mtax.__index = _mtax;

local NUI_ACTIONS = {
	"getPlayers",
	"moderatePlayer", "spectatePlayer", "slapPlayer", "shoutPlayer",
	"setPlayerStat", "resetPlayerStats",
	"givePlayerWeapon", "givePlayerVehicle", "givePlayerJetpack",
	"warpToPlayer", "warpPlayerToMe",
	"vehicleMaintenance", "setVehicleDimension", "teleportPlayerToInterior",
	"getVehicleCustomization", "vehicleCustomizeAction",

	"getResources", "resourceLifecycle", "refreshResources", "executeCommand", "getActionLog",

	"getServerSettings", "setServerPassword",
	"setWeather", "setTime", "setGravity", "setGameSpeed", "setWaveHeight", "setFpsLimit",
	"sendWelcomeMessage", "shutdownServer", "clearChat",

	"getBans", "searchBans", "banRowAction", "banByField", "refreshBans",

	"getAclGroups", "aclGroupAction",
};

function _mtax:New()
	local instance = setmetatable({}, self)
	instance.isOpen = false
	instance.pendingCallbacks = {}
	instance.nextRequestId = 0
	return instance
end

function _mtax:SetVisible(visible)
	self.isOpen = visible
	setNuiFocus(visible, visible)
	sendNuiMessage({ action = "toggle", data = visible })
end

function _mtax:TogglePanel()
	triggerServerEvent("mtax:admin:requestToggle", localPlayer)
end

function _mtax:RegisterNuiBridge()
	for _, action in ipairs(NUI_ACTIONS) do
		registerNuiCallback(action, function(data, cb)
			self.nextRequestId = self.nextRequestId + 1
			local requestId = self.nextRequestId
			self.pendingCallbacks[requestId] = cb
			triggerServerEvent("mtax:admin:nui:" .. action, localPlayer, requestId, data)
		end)
	end

	registerNuiCallback("closePanel", function(data, cb)
		self:SetVisible(false)
		triggerServerEvent("mtax:admin:closePanel", localPlayer)
		cb({ ok = true })
	end)

	addEvent("mtax:admin:response", true)
	addEventHandler("mtax:admin:response", root, function(requestId, result)
		local cb = self.pendingCallbacks[requestId]
		if cb then
			cb(result)
			self.pendingCallbacks[requestId] = nil
		end
	end)
end

function _mtax:RegisterServerRelays()
	addEvent("mtax:admin:setVisible", true)
	addEventHandler("mtax:admin:setVisible", root, function(visible)
		self:SetVisible(visible)
	end)

	addEvent("mtax:admin:setPlayers", true)
	addEventHandler("mtax:admin:setPlayers", root, function(players)
		sendNuiMessage({ action = "setPlayers", data = players })
	end)

	addEvent("mtax:admin:setResources", true)
	addEventHandler("mtax:admin:setResources", root, function(resources)
		sendNuiMessage({ action = "setResources", data = resources })
	end)

	addEvent("mtax:admin:setBans", true)
	addEventHandler("mtax:admin:setBans", root, function(bans)
		sendNuiMessage({ action = "setBans", data = bans })
	end)

	addEvent("mtax:admin:setAclGroups", true)
	addEventHandler("mtax:admin:setAclGroups", root, function(groups)
		sendNuiMessage({ action = "setAclGroups", data = groups })
	end)

	addEvent("mtax:admin:setServerSettings", true)
	addEventHandler("mtax:admin:setServerSettings", root, function(settings)
		sendNuiMessage({ action = "setServerSettings", data = settings })
	end)

	addEvent("mtax:admin:setActionLog", true)
	addEventHandler("mtax:admin:setActionLog", root, function(log)
		sendNuiMessage({ action = "setActionLog", data = log })
	end)

	addEvent("mtax:admin:runClientCommand", true)
	addEventHandler("mtax:admin:runClientCommand", root, function(command, args)
		executeCommandHandler(command, args)
	end)

	addEvent("mtax:admin:setFpsLimit", true)
	addEventHandler("mtax:admin:setFpsLimit", root, function(limit)
		if setFPSLimit then
			setFPSLimit(limit)
		end
	end)
end

function _mtax:Init()
	addCommandHandler(Config.Command, function()
		self:TogglePanel()
	end)

	if Config.OpenKey and Config.OpenKey ~= "" then
		bindKey(Config.OpenKey, "down", function()
			self:TogglePanel()
		end)
	end

	self:RegisterNuiBridge()
	self:RegisterServerRelays()

	addEventHandler("onClientResourceStop", resourceRoot, function()
		setNuiFocus(false, false)
	end)
end

CreateThread(function()
	local Main = _mtax:New()
	Main:Init()
end)