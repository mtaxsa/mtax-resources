---@alias Element userdata

local TOGGLE_COOLDOWN = 250

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Open = false
    self.Id = false
    self.Admin = false
    self.Enabled = true
    self.CanToggle = true
    self.Session = false

    --- Add Events
    addEventHandler("onClientResourceStart", resourceRoot, function() self:ResourceStart() end)
    addEventHandler("onClientResourceStop", resourceRoot, function() self:ResourceStop() end)

    --- Register Nui
    registerNuiCallback("ready", function(_, Callback) self:ReadyCallback(Callback) end)
    registerNuiCallback("close", function(_, Callback) self:CloseCallback(Callback) end)
    registerNuiCallback("send", function(Data, Callback) self:SendCallback(Data, Callback) end)
    registerNuiCallback("command", function(Data, Callback) self:CommandCallback(Data, Callback) end)

    bindKey(Config.Key, "down", function() self:KeyPressed() end)
end

function _MTAX:LockToggle()
    self.CanToggle = false
    setTimer(function() self.CanToggle = true end, TOGGLE_COOLDOWN, 1)
end

--- Boot

---@return table
function _MTAX:BootPayload()
    local Types = {}
    for Id, Kind in pairs(Config.Types) do
        Types[Id] = {
            label = Kind.Label,
            color = Kind.Color,
            form  = Kind.Form,
            fade  = Kind.Fade,
        }
    end

    local Tabs = {}
    for _, Id in ipairs(Config.Tabs) do
        if Config.Types[Id] then
            Tabs[#Tabs + 1] = Id
        end
    end

    local Suggestions = {}
    for _, Entry in ipairs(Config.Suggestions) do
        Suggestions[#Suggestions + 1] = {
            name   = Entry.Name,
            params = Entry.Params,
            help   = Entry.Help,
        }
    end

    return {
        types       = Types,
        tabs        = Tabs,
        defaultTab  = Config.Types[Config.DefaultTab] and Config.DefaultTab or Tabs[1],
        suggestions = Suggestions,
        stickers    = Config.Stickers,
        history     = Config.HistorySize,
        maxLength   = Config.MaxLength,
        hideAfter   = Config.HideAfter,
        timestamps  = Config.Timestamps,
        openKey     = Config.Key,
    }
end

function _MTAX:RequestSession()
    Server.ready(function(Id, Roster, Enabled, Admin)
        if not Id then
            return
        end

        self.Id = Id
        self.Admin = Admin == true
        self.Enabled = Enabled ~= false
        self.Session = { id = Id, roster = Roster, enabled = self.Enabled, admin = self.Admin }

        sendNuiMessage({ action = "session", data = self.Session })
    end)
end

---@param Callback function
function _MTAX:ReadyCallback(Callback)
    Callback({ boot = self:BootPayload(), session = self.Session })
end

function _MTAX:ResourceStart()
    sendNuiMessage({ action = "boot", data = self:BootPayload() })
    self:RequestSession()

    setTimer(function()
        if not self.Id then
            self:RequestSession()
        end
    end, 3000, 1)
end

function _MTAX:ResourceStop()
    if self.Open then
        setNuiFocus(false, false)
    end
end

--- Focus

---@param Open boolean
function _MTAX:SetOpen(Open)
    self.Open = Open
    setNuiFocus(Open, Open and Config.Cursor or false)
    sendNuiMessage({ action = "toggle", data = Open })
end

function _MTAX:KeyPressed()
    if self.Open or not self.CanToggle or isNuiFocused() then
        return
    end

    self:LockToggle()
    self:SetOpen(true)
end

--- Nui

---@param Callback function
function _MTAX:CloseCallback(Callback)
    if self.Open and self.CanToggle then
        self:LockToggle()
        self:SetOpen(false)
    end

    Callback({ ok = true })
end

---@param Data table
---@param Callback function
function _MTAX:SendCallback(Data, Callback)
    if type(Data) ~= "table" then
        Callback({ ok = false })
        return
    end

    Server.send(false, tostring(Data.type or ""), tostring(Data.text or ""), Data.sticker, Data.target)
    Callback({ ok = true })
end

---@param Data table
---@param Callback function
function _MTAX:CommandCallback(Data, Callback)
    local Line = type(Data) == "table" and tostring(Data.line or "") or ""
    local Name, Args = Line:match("^(%S+)%s*(.*)$")

    if not Name then
        Callback({ ok = false })
        return
    end

    local HandledHere = executeCommandHandler(Name, Args) == true

    Server.command(function(HandledThere)
        if HandledHere or HandledThere == true then
            return
        end

        self:Print(string.format(Config.Text.Unknown, Name))
    end, Name, Args)

    Callback({ ok = true })
end

--- Output
---@param Text string
---@param Color? string
---@param Segments? table[]
function _MTAX:Print(Text, Color, Segments)
    sendNuiMessage({
        action = "message",
        data = {
            kind      = "system",
            text      = Text,
            color     = Color,
            segments  = Segments,
            time      = ChatText:Timestamp(),
            localOnly = true,
        },
    })
end

---@param Text string
---@param R? number
---@param G? number
---@param B? number
---@param ColorCoded? boolean
---@return boolean
function _MTAX:OutputChatBox(Text, R, G, B, ColorCoded)
    if type(Text) ~= "string" then
        return false
    end

    local Color = ChatText:Rgb(R, G, B)
    local Clean = ChatText:Line(Text)
    local Segments = nil

    if ColorCoded then
        Clean, Segments = ChatText:ColorCoded(Clean, Color)
    end

    self:Print(Clean, Color, Segments)
    return true
end

local Main = _MTAX:New()

Main:Init()

--- Tunnel

Client.receive = function(Message, Anchor)
    if type(Message) ~= "table" then
        return
    end

    sendNuiMessage({ action = "message", data = Message })

    if Message.three and isElement(Anchor) then
        Labels:Push(Anchor, Message)
    end
end

Client.roster = function(Roster)
    sendNuiMessage({ action = "roster", data = Roster })
end

Client.clear = function()
    Labels:Clear()
    sendNuiMessage({ action = "clear" })
end

Client.enabled = function(Enabled)
    Main.Enabled = Enabled == true
    sendNuiMessage({ action = "enabled", data = Main.Enabled })
end

--- Exports

---@param Text string
---@param R? number
---@param G? number
---@param B? number
---@param ColorCoded? boolean
---@return boolean
function outputChatBox(Text, R, G, B, ColorCoded)
    return Main:OutputChatBox(Text, R, G, B, ColorCoded)
end

---@return boolean
function clearChat()
    Client.clear()
    return true
end

---@return boolean
function isChatEnabled()
    return Main.Enabled
end

---@return number|false
function getPlayerChatID()
    return Main.Id
end
