local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Resource = getResourceName(getThisResource())
    self.Binds = {}
    self.Commands = {}

    self.KeyHandler = function(Key, KeyState) self:KeyPressed(Key, KeyState) end
    self.CommandHandler = function(CommandName, ...) self:CommandCalled(CommandName, ...) end

    --- Register Events
    addEvent("registerBindKey:" .. self.Resource, true)
    addEvent("unregisterBindKey:" .. self.Resource, true)
    addEvent("registerCommandHandler:" .. self.Resource, true)
    addEvent("unregisterCommandHandler:" .. self.Resource, true)

    --- Add Events
    addEventHandler("registerBindKey:" .. self.Resource, root, function(...) self:RegisterBindKey(...) end)
    addEventHandler("unregisterBindKey:" .. self.Resource, root, function(...) self:UnregisterBindKey(...) end)
    addEventHandler("registerCommandHandler:" .. self.Resource, root, function(...) self:RegisterCommandHandler(...) end)
    addEventHandler("unregisterCommandHandler:" .. self.Resource, root, function(...) self:UnregisterCommandHandler(...) end)
    addEventHandler("onClientResourceStart", resourceRoot, function() self:ResourceStart() end)
end

function _MTAX:Accounts()
    return exports["accounts"]
end

function _MTAX:Chat()
    return exports["chat"]
end

function _MTAX:KeyPressed(Key, KeyState)
    Key = Key:lower()

    triggerServerEvent("callbackBindKey:" .. self.Resource, localPlayer, Key, KeyState)
end

function _MTAX:CommandCalled(CommandName, ...)
    triggerServerEvent("callbackCommandHandler:" .. self.Resource, localPlayer, CommandName, ...)
end

function _MTAX:RegisterBindKey(Key, KeyState)
    Key = Key:lower()

    local Id = Key .. ":" .. KeyState
    if self.Binds[Id] then
        return
    end

    if bindKey(Key, KeyState, self.KeyHandler) then
        self.Binds[Id] = true
    end
end

function _MTAX:UnregisterBindKey(Key, KeyState)
    Key = Key:lower()

    local Id = Key .. ":" .. KeyState
    if not self.Binds[Id] then
        return
    end

    unbindKey(Key, KeyState, self.KeyHandler)
    self.Binds[Id] = nil
end

function _MTAX:RegisterCommandHandler(CommandName, CaseSensitive)
    if self.Commands[CommandName] then
        return
    end

    if addCommandHandler(CommandName, self.CommandHandler, CaseSensitive) then
        self.Commands[CommandName] = true
    end
end

function _MTAX:UnregisterCommandHandler(CommandName)
    if not self.Commands[CommandName] then
        return
    end

    removeCommandHandler(CommandName, self.CommandHandler)
    self.Commands[CommandName] = nil
end

function _MTAX:ResourceStart()
    triggerServerEvent("requestCommandHandlers:" .. self.Resource, localPlayer)
end

local Main = _MTAX:New()

Main:Init()

--- Chat

---@param Text string
---@param R? number
---@param G? number
---@param B? number
---@param ColorCoded? boolean
---@return boolean
function outputChatBox(Text, R, G, B, ColorCoded)
    return Main:Chat():outputChatBox(Text, R, G, B, ColorCoded)
end

---@return boolean
function clearChatBox()
    return Main:Chat():clearChat()
end

---@param Show boolean
---@param InputBlocked? boolean
---@return boolean
function showChat(Show, InputBlocked)
    return Main:Chat():showChat(Show, InputBlocked)
end

---@return boolean
function isChatVisible()
    return Main:Chat():isChatVisible()
end

---@return boolean
function isChatInputBlocked()
    return Main:Chat():isChatInputBlocked()
end

--- Accounts

---@return number
function getPlayerMoney()
    return Main:Accounts():getPlayerMoney()
end

---@param Amount number
---@param Instant? boolean
---@return boolean
function setPlayerMoney(Amount, Instant)
    return Main:Accounts():setPlayerMoney(Amount, Instant)
end

---@param Amount number
---@return boolean
function givePlayerMoney(Amount)
    return Main:Accounts():givePlayerMoney(Amount)
end

---@param Amount number
---@return boolean
function takePlayerMoney(Amount)
    return Main:Accounts():takePlayerMoney(Amount)
end

---@return string|false
function getPlayerSerial()
    return Main:Accounts():getPlayerSerial()
end

--- Graphics

local nativeDxGetStatus = dxGetStatus

---@return table|false
function dxGetStatus(...)
    local Status = nativeDxGetStatus(...)
    if type(Status) == "table" then
        Status.VideoMemoryFreeForMTA = Status.VideoMemoryFreeForMTAX
    end
    return Status
end

--- Events

local nativeAddEventHandler = addEventHandler
local nativeRemoveEventHandler = removeEventHandler
local nativeGetEventHandlers = getEventHandlers

-- Handlers of an MTA event name are attached to its MTAX event, so they get its source, arguments and dispatch
-- (a re-trigger would repeat once per resource that loads this file); eventName still reads the MTA name.
local EventAliases = {
    onClientMTAFocusChange = "onClientMTAXFocusChange",
}

local AliasForwarders = {}
local AliasHandlers = setmetatable({}, { __mode = "k" })

for Name in pairs(EventAliases) do
    AliasForwarders[Name] = setmetatable({}, { __mode = "k" })
end

local function forwarderFor(Name, Handler)
    local Forwarders = AliasForwarders[Name]
    local Forwarder = Forwarders[Handler]
    if not Forwarder then
        Forwarder = function(...)
            local NativeName = eventName
            eventName = Name
            Handler(...)
            eventName = NativeName
        end
        Forwarders[Handler] = Forwarder
        AliasHandlers[Forwarder] = Handler
    end
    return Forwarder
end

---@return boolean
function addEventHandler(Name, AttachedTo, Handler, ...)
    local Alias = EventAliases[Name]
    if Alias and type(Handler) == "function" then
        return nativeAddEventHandler(Alias, AttachedTo, forwarderFor(Name, Handler), ...)
    end
    return nativeAddEventHandler(Name, AttachedTo, Handler, ...)
end

---@return boolean
function removeEventHandler(Name, AttachedTo, Handler)
    local Alias = EventAliases[Name]
    local Forwarder = Alias and type(Handler) == "function" and AliasForwarders[Name][Handler]
    if Forwarder then
        return nativeRemoveEventHandler(Alias, AttachedTo, Forwarder)
    end
    return nativeRemoveEventHandler(Name, AttachedTo, Handler)
end

---@return table|false
function getEventHandlers(Name, AttachedTo)
    local Alias = EventAliases[Name]
    if not Alias then
        return nativeGetEventHandlers(Name, AttachedTo)
    end
    local Handlers = nativeGetEventHandlers(Alias, AttachedTo)
    if type(Handlers) ~= "table" then
        return Handlers
    end
    local Result = {}
    for _, Forwarder in ipairs(Handlers) do
        local Handler = AliasHandlers[Forwarder]
        if Handler then
            Result[#Result + 1] = Handler
        end
    end
    return Result
end
