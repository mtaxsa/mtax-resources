---@alias Element userdata

local NORMAL_GRAVITY = 0.008
local STATE_INTERVAL = 200
local POSITIONS_INTERVAL = 750
local TOGGLE_COOLDOWN = 250
local SESSION_RETRY = 3000

local SKIN_INTERVAL = 300
local SKIN_SETTLE = 900
local SKIN_VERIFY = 1500
local STAT_VERIFY = 700
local CAMERA_HOLD = 350
local CAMERA_WATCH = 4000

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Session = false
    self.Options = Config.Options
    self.Bookmarks = {}
    self.Gravity = NORMAL_GRAVITY
    self.Frozen = false
    self.MinuteDuration = nil

    self.Windows = {}
    self.Focused = false
    self.StateTimer = nil
    self.LastState = nil
    self.Toggles = {}

    self.Positions = {}
    self.PositionsAt = 0
    self.Clothes = nil
    self.ClothesPending = false

    self.Skin = { At = 0, Id = nil, Pending = nil, PendingTimer = nil, VerifyTimer = nil }
    self.CameraWatch = nil
    self.StatTimers = {}

    self.CameraHandler = function() self:WatchCamera() end

    --- Add Events
    addEventHandler("onClientResourceStart", resourceRoot, function() self:ResourceStart() end)
    addEventHandler("onClientResourceStop", resourceRoot, function() self:ResourceStop() end)

    self:RegisterNui()
    self:RegisterKeys()
    self:RegisterCommands()
end

--- Helpers

---@param Path string
---@return any
function _MTAX:Option(Path)
    local Node = self.Options

    for Part in Path:gmatch("[^%.]+") do
        if type(Node) ~= "table" then
            return nil
        end

        Node = Node[Part]
    end

    return Node
end

---@param Key string
---@param Vars? table
---@param Kind? string
---@return boolean
function _MTAX:Notify(Key, Vars, Kind)
    sendNuiMessage({ action = "toast", data = { key = Key, vars = Vars or {}, kind = Kind or "error" } })
    return false
end

---@param Option string
---@param Message? string
---@return boolean
function _MTAX:Allowed(Option, Message)
    if self:Option(Option) then
        return true
    end

    return self:Notify(Message or "error.action_not_allowed")
end

---@param Driver? boolean
---@return Element|nil
function _MTAX:Vehicle(Driver)
    local Vehicle = getPedOccupiedVehicle(localPlayer)

    if not Vehicle then
        self:Notify("error.need_vehicle")
        return nil
    end

    if Driver and getVehicleController(Vehicle) ~= localPlayer then
        self:Notify("error.driver_only")
        return nil
    end

    return Vehicle
end

---@param Value any
---@param Low number
---@param High number
---@param Fallback number
---@return number
function _MTAX:Clamp(Value, Low, High, Fallback)
    return math.max(Low, math.min(High, math.floor(tonumber(Value) or Fallback)))
end

---@return boolean
function _MTAX:IsAiming()
    return getPedTask(localPlayer, "secondary", 0) == "TASK_SIMPLE_USE_GUN"
        or isPedDoingGangDriveby(localPlayer)
        or isPedReloadingWeapon(localPlayer)
end

---@return boolean
function _MTAX:IsMoving()
    local X, Y, Z = getElementVelocity(localPlayer)
    return math.abs(X) + math.abs(Y) + math.abs(Z) > 0.008
end

---@param Player Element
---@return string
function _MTAX:PlayerName(Player)
    local Name = getPlayerName(Player) or "?"

    if self:Option("removeHex") then
        Name = Name:gsub("#%x%x%x%x%x%x", "")
    end

    return Name
end

---@param Part? string
---@return Element|nil
function _MTAX:FindPlayer(Part)
    if not Part then
        return nil
    end

    Part = Part:lower()

    for _, Player in ipairs(getElementsByType("player")) do
        if (getPlayerName(Player) or ""):gsub("#%x%x%x%x%x%x", ""):lower():find(Part, 1, true) then
            return Player
        end
    end

    return nil
end

--- Boot

---@return table
function _MTAX:BootPayload()
    return {
        language = Config.Language,
        keys = {
            panel   = Config.Keys.Panel:upper(),
            map     = Config.Keys.Map:upper(),
            jetpack = Config.Keys.Jetpack:upper(),
        },
    }
end

---@return table
function _MTAX:SessionPayload()
    return { options = self.Options, bookmarks = self.Bookmarks }
end

function _MTAX:RequestSession()
    Server.ready(function(Options, Bookmarks, Flags, Gravity)
        if type(Options) ~= "table" then
            return
        end

        self.Options = Options
        self.Bookmarks = type(Bookmarks) == "table" and Bookmarks or {}
        self.Gravity = tonumber(Gravity) or NORMAL_GRAVITY
        self.Session = true

        Peers:Load(Flags)
        sendNuiMessage({ action = "session", data = self:SessionPayload() })
    end)
end

function _MTAX:ResourceStart()
    setJetpackMaxHeight(Config.JetpackMaxHeight)
    setAircraftMaxHeight(Config.AircraftMaxHeight)

    sendNuiMessage({ action = "boot", data = self:BootPayload() })
    self:RequestSession()

    setTimer(function()
        if not self.Session then
            self:RequestSession()
        end
    end, SESSION_RETRY, 1)
end

function _MTAX:ResourceStop()
    setNuiFocus(false, false)
    setPedAnimation(localPlayer, false)

    if self.Frozen then
        self:FreezeTime(false)
    end
end

--- Windows

---@param Ids any
function _MTAX:SetWindows(Ids)
    self.Windows = {}

    for _, Id in ipairs(type(Ids) == "table" and Ids or {}) do
        self.Windows[tostring(Id)] = true
    end

    local Open = next(self.Windows) ~= nil
    setNuiFocus(Open, Open)

    if Open == self.Focused then
        return
    end

    self.Focused = Open

    if Open then
        self.LastState = nil
        self:PushState()
        self.StateTimer = setTimer(function() self:PushState() end, STATE_INTERVAL, 0)
    elseif isTimer(self.StateTimer) then
        killTimer(self.StateTimer)
        self.StateTimer = nil
    end
end

---@param Id string
function _MTAX:Toggle(Id)
    local Now = getTickCount()
    if self.Toggles[Id] and Now - self.Toggles[Id] < TOGGLE_COOLDOWN then
        return
    end

    self.Toggles[Id] = Now
    sendNuiMessage({ action = "toggle", data = Id })
end

---@param Id string
function _MTAX:OpenTool(Id)
    sendNuiMessage({ action = "open", data = Id })
end

--- State

---@return table
function _MTAX:CollectState()
    local Vehicle = getPedOccupiedVehicle(localPlayer)
    local X, Y, Z = getElementPosition(localPlayer)
    local Hour, Minute = getTime()

    local State = {
        x         = math.floor((tonumber(X) or 0) * 10) / 10,
        y         = math.floor((tonumber(Y) or 0) * 10) / 10,
        z         = math.floor((tonumber(Z) or 0) * 10) / 10,
        interior  = getElementInterior(localPlayer),
        dimension = getElementDimension(localPlayer),
        vehicle   = Vehicle and getVehicleName(Vehicle) or false,
        driver    = Vehicle and getVehicleController(Vehicle) == localPlayer or false,
        health    = 0,
        lights    = 0,
        jetpack   = isPedWearingJetpack(localPlayer) == true,
        bike      = canPedBeKnockedOffBike(localPlayer) == true,
        warping   = Peers:Get(localPlayer, "warping"),
        knifing   = Peers:Get(localPlayer, "knifing"),
        ghostmode = Peers:Get(localPlayer, "ghostmode"),
        frozen    = self.Frozen,
        hour      = Hour,
        minute    = Minute,
        skin      = getElementModel(localPlayer),
        gravity   = math.floor(self.Gravity * 100000 + 0.5) / 100000,
        speed     = math.floor(getGameSpeed() * 100 + 0.5) / 100,
        fight     = getPedFightingStyle(localPlayer),
        dead      = isPedDead(localPlayer) == true,
    }

    if Vehicle then
        State.health = math.max(0, math.min(100, math.floor((getElementHealth(Vehicle) - 250) / 7.5)))
        State.lights = getVehicleOverrideLights(Vehicle) or 0
    end

    return State
end

function _MTAX:PushState()
    local State = self:CollectState()
    local Last = self.LastState

    if Last then
        local Changed = false

        for Key, Value in pairs(State) do
            if Last[Key] ~= Value then
                Changed = true
                break
            end
        end

        if not Changed then
            return
        end
    end

    self.LastState = State
    sendNuiMessage({ action = "state", data = State })
end

--- Other players

function _MTAX:RefreshPositions()
    local Now = getTickCount()
    if Now - self.PositionsAt < POSITIONS_INTERVAL then
        return
    end

    self.PositionsAt = Now

    Server.positions(function(List)
        if type(List) ~= "table" then
            return
        end

        local Positions = {}
        for _, Entry in ipairs(List) do
            if isElement(Entry.player) then
                Positions[Entry.player] = Entry
            end
        end

        self.Positions = Positions
    end)
end

-- Streamed players are read locally; far ones come from the server snapshot.
---@param Player Element
---@return number?, number?, number?, number?, number?, string|false|nil
function _MTAX:PlayerPosition(Player)
    if Player == localPlayer or isElementStreamedIn(Player) then
        local X, Y, Z = getElementPosition(Player)
        local Vehicle = getPedOccupiedVehicle(Player)
        return X, Y, Z, getElementInterior(Player), getElementDimension(Player), Vehicle and getVehicleName(Vehicle) or false
    end

    local Known = self.Positions[Player]
    if not Known then
        return nil
    end

    return Known.x, Known.y, Known.z, Known.interior, Known.dimension, Known.vehicle
end

---@return table[]
function _MTAX:PlayerList()
    self:RefreshPositions()

    local MX, MY, MZ = getElementPosition(localPlayer)
    local List = {}

    for _, Player in ipairs(getElementsByType("player")) do
        if Player ~= localPlayer then
            local X, Y, Z, _, _, Vehicle = self:PlayerPosition(Player)

            List[#List + 1] = {
                key      = getPlayerName(Player),
                name     = self:PlayerName(Player),
                vehicle  = Vehicle or false,
                distance = X and math.floor(getDistanceBetweenPoints3D(X, Y, Z, MX, MY, MZ)) or false,
                blocked  = Peers:Get(Player, "warping"),
            }
        end
    end

    table.sort(List, function(A, B) return A.name:lower() < B.name:lower() end)
    return List
end

---@return table
function _MTAX:Blips()
    self:RefreshPositions()

    local Dimension = getElementDimension(localPlayer)
    local List = {}

    for _, Player in ipairs(getElementsByType("player")) do
        local X, Y, _, Interior, Other = self:PlayerPosition(Player)

        if X and Interior == 0 and Other == Dimension then
            List[#List + 1] = {
                x    = math.floor(X),
                y    = math.floor(Y),
                key  = getPlayerName(Player),
                name = self:PlayerName(Player),
                me   = Player == localPlayer,
            }
        end
    end

    return { blips = List, dead = isPedDead(localPlayer) == true }
end

---@param Player Element
---@return boolean
function _MTAX:WarpTo(Player)
    if not isElement(Player) or Player == localPlayer then
        return self:Notify("error.choose_other_player")
    end

    if not self:Allowed("warp", "error.warp_disabled") then
        return false
    end

    if Peers:Get(Player, "warping") then
        return self:Notify("error.player_blocked_warp")
    end

    local Vehicle = getPedOccupiedVehicle(localPlayer)
    if Vehicle and getVehicleController(Vehicle) ~= localPlayer then
        return self:Notify("error.driver_teleport_only")
    end

    Server.warpTo(function(X, Y, Z, Rotation, Interior, Dimension)
        if not tonumber(X) then
            return
        end

        local Angle = math.rad((tonumber(Rotation) or 0) + 90)
        Teleport:To(X + math.cos(Angle) * 3, Y + math.sin(Angle) * 3, Z, Interior, Dimension)
    end, Player)

    return true
end

--- Ped

function _MTAX:WatchCamera()
    local Watch = self.CameraWatch
    local Now = getTickCount()

    if not Watch or Now > Watch.Expires then
        self:StopCameraWatch()
        return
    end

    if getElementModel(localPlayer) == Watch.Model then
        return
    end

    Watch.ChangedAt = Watch.ChangedAt or Now
    setPedCameraRotation(localPlayer, Watch.Rotation)

    if Now - Watch.ChangedAt > CAMERA_HOLD then
        self:StopCameraWatch()
    end
end

function _MTAX:StopCameraWatch()
    if self.CameraWatch then
        self.CameraWatch = nil
        removeEventHandler("onClientRender", root, self.CameraHandler)
    end
end

-- A model swap snaps the camera behind the ped; hold the old rotation while it happens.
function _MTAX:StartCameraWatch()
    local Rotation = getPedCameraRotation(localPlayer)
    if type(Rotation) ~= "number" then
        return
    end

    if not self.CameraWatch then
        addEventHandler("onClientRender", root, self.CameraHandler)
    end

    self.CameraWatch = {
        Rotation = Rotation,
        Model    = getElementModel(localPlayer),
        Expires  = getTickCount() + CAMERA_WATCH,
    }
end

---@param Id number
function _MTAX:SendSkin(Id)
    local Skin = self.Skin

    Skin.At = getTickCount()
    Skin.Id = Id

    self:StartCameraWatch()

    if getPedAnimation(localPlayer) then
        Server.stopAnimation(false)
    end

    Server.skin(false, Id)

    if isTimer(Skin.VerifyTimer) then
        killTimer(Skin.VerifyTimer)
    end

    Skin.VerifyTimer = setTimer(function()
        Skin.VerifyTimer = nil

        if Skin.Id == Id and not Skin.Pending and getElementModel(localPlayer) ~= Id then
            self:Notify("error.skin_not_applied")
        end
    end, SKIN_VERIFY, 1)
end

---@param Id any
---@return boolean
function _MTAX:SetSkin(Id)
    Id = tonumber(Id)
    if not Id then
        return self:Notify("error.invalid_skin")
    end

    if not self:Allowed("setskin") then
        return false
    end

    local Skin = self.Skin
    local Since = getTickCount() - Skin.At
    local Settling = Skin.At > 0 and Since < SKIN_SETTLE

    if not Settling and self:IsMoving() then
        return self:Notify("error.stop_before_skin")
    end

    -- Rapid clicks collapse into the last skin picked.
    if Skin.At > 0 and Since < SKIN_INTERVAL then
        Skin.Pending = Id

        if not isTimer(Skin.PendingTimer) then
            Skin.PendingTimer = setTimer(function()
                local Next = Skin.Pending
                Skin.Pending = nil
                Skin.PendingTimer = nil

                if Next and getElementModel(localPlayer) ~= Next then
                    self:SendSkin(Next)
                end
            end, SKIN_INTERVAL - Since, 1)
        end

        return true
    end

    self:SendSkin(Id)
    return true
end

---@param Block any
---@param Name any
---@return boolean
function _MTAX:PlayAnimation(Block, Name)
    if self:IsAiming() then
        return self:Notify("error.stop_aiming")
    end

    Server.animation(false, tostring(Block or ""), tostring(Name or ""))
    return true
end

function _MTAX:StopAnimation()
    if getPedAnimation(localPlayer) then
        Server.stopAnimation(false)
    end
end

---@param Id any
---@param Ammo any
---@return boolean
function _MTAX:GiveWeapon(Id, Ammo)
    if not tonumber(Id) then
        return self:Notify("error.invalid_weapon")
    end

    if self:IsAiming() then
        return self:Notify("error.stop_aiming")
    end

    Server.weapon(false, tonumber(Id), self:Clamp(Ammo, 1, 9999, 500))
    return true
end

---@param Id number
---@return number|nil
function _MTAX:StatValue(Id)
    local Value = getPedStat(localPlayer, Id)
    return type(Value) == "number" and math.floor(Value + 0.5) or nil
end

---@param Ids any
---@return table[]
function _MTAX:StatValues(Ids)
    local List = {}

    for _, Id in ipairs(type(Ids) == "table" and Ids or {}) do
        Id = tonumber(Id)
        if Id then
            List[#List + 1] = { id = Id, value = self:StatValue(Id) or 0 }
        end
    end

    return List
end

---@param Id any
---@param Value any
---@param Label? string
---@return boolean
function _MTAX:SetStat(Id, Value, Label)
    Id = tonumber(Id)
    if not Id or not self:Allowed("stats") then
        return false
    end

    Value = self:Clamp(Value, 0, 1000, 1000)
    Label = tostring(Label or Id)

    Server.stat(false, Id, Value)

    if isTimer(self.StatTimers[Id]) then
        killTimer(self.StatTimers[Id])
    end

    -- Other resources may pin stats; tell the player when the value did not stick.
    self.StatTimers[Id] = setTimer(function()
        self.StatTimers[Id] = nil

        local Applied = self:StatValue(Id)
        if Applied and math.abs(Applied - Value) <= 1 then
            self:Notify("notify.stat_applied", { stat = Label, value = Applied }, "success")
        else
            self:Notify("error.stat_not_applied", { stat = Label, value = tostring(Applied or "?") })
        end
    end, STAT_VERIFY, 1)

    return true
end

---@param Value any
---@return boolean
function _MTAX:SetGravity(Value)
    Value = tonumber(Value)
    if not Value then
        return self:Notify("error.invalid_gravity")
    end

    Server.gravity(function(Gravity)
        self.Gravity = tonumber(Gravity) or self.Gravity
    end, math.max(-1, math.min(1, Value)))

    return true
end

---@param Enabled? boolean
function _MTAX:SetJetpack(Enabled)
    if Enabled == nil then
        Enabled = not isPedWearingJetpack(localPlayer)
    end

    if Enabled and not self:Allowed("jetpack", "error.jetpack_disabled") then
        return
    end

    Server.jetpack(false, Enabled)
end

function _MTAX:Suicide()
    if self:Allowed("kill", "error.suicide_disabled") then
        Server.kill(false)
    end
end

--- Clothes

---@return table
function _MTAX:ClothesCatalog()
    if self.Clothes then
        return { groups = self.Clothes }
    end

    if not self.ClothesPending then
        self.ClothesPending = true

        Server.clothes(function(Groups)
            self.ClothesPending = false

            if type(Groups) == "table" then
                self.Clothes = Groups
                sendNuiMessage({ action = "clothes", data = Groups })
            end
        end)
    end

    return { groups = false }
end

---@return boolean
function _MTAX:CanDress()
    if getElementModel(localPlayer) ~= 0 then
        return self:Notify("error.cj_skin_required")
    end

    return true
end

--- Bookmarks

---@param List table[]
function _MTAX:SetBookmarks(List)
    self.Bookmarks = List
    sendNuiMessage({ action = "bookmarks", data = List })
end

---@param Name any
function _MTAX:AddBookmark(Name)
    Server.addBookmark(function(List)
        if type(List) == "table" then
            self:SetBookmarks(List)
            self:Notify("notify.bookmark_saved", nil, "success")
        end
    end, tostring(Name or ""))
end

---@param Index any
function _MTAX:DeleteBookmark(Index)
    Server.deleteBookmark(function(List)
        if type(List) == "table" then
            self:SetBookmarks(List)
        end
    end, tonumber(Index))
end

---@param Index any
---@return boolean
function _MTAX:GoToBookmark(Index)
    local Mark = self.Bookmarks[tonumber(Index) or 0]
    if not Mark then
        return false
    end

    return Teleport:To(Mark.x, Mark.y, Mark.z, Mark.interior, Mark.dimension)
end

--- Vehicle

---@param Id any
function _MTAX:CreateVehicle(Id)
    if not tonumber(Id) then
        return self:Notify("error.invalid_model")
    end

    if self:Allowed("createvehicle", "error.vehicle_creation_disabled") then
        Server.vehicle(false, tonumber(Id))
    end
end

function _MTAX:FlipVehicle()
    local Vehicle = self:Vehicle(true)
    if not Vehicle then
        return
    end

    local _, _, Rotation = getElementRotation(Vehicle)
    setElementRotation(Vehicle, 0, 0, Rotation)
    setElementVelocity(Vehicle, 0, 0, 0)
end

---@return table
function _MTAX:UpgradeList()
    local Vehicle = getPedOccupiedVehicle(localPlayer)
    if not Vehicle then
        return { vehicle = false, items = {} }
    end

    local Installed = {}
    for _, Id in ipairs(getVehicleUpgrades(Vehicle) or {}) do
        Installed[Id] = true
    end

    local Items = {}
    for _, Id in ipairs(getVehicleCompatibleUpgrades(Vehicle) or {}) do
        Items[#Items + 1] = {
            id        = Id,
            slot      = getVehicleUpgradeSlotName(Id) or "Other",
            installed = Installed[Id] == true,
        }
    end

    return { vehicle = true, items = Items }
end

---@param Id any
function _MTAX:ToggleUpgrade(Id)
    local Vehicle = self:Vehicle()
    Id = tonumber(Id)

    if not Vehicle or not Id then
        return
    end

    for _, Installed in ipairs(getVehicleUpgrades(Vehicle) or {}) do
        if Installed == Id then
            Server.upgrade(false, Id, false)
            return
        end
    end

    Server.upgrade(false, Id, true)
end

---@param Slot any
---@return number[]|nil
function _MTAX:VehicleColor(Slot)
    local Vehicle = getPedOccupiedVehicle(localPlayer)
    Slot = tonumber(Slot) or 1

    if not Vehicle then
        return nil
    end

    if Slot == 5 then
        local R, G, B = getVehicleHeadLightColor(Vehicle)
        return R and { R, G, B } or nil
    end

    local Values = { getVehicleColor(Vehicle, true) }
    local Offset = (Slot - 1) * 3

    if not Values[Offset + 1] then
        return nil
    end

    return { Values[Offset + 1], Values[Offset + 2], Values[Offset + 3] }
end

---@param Slot any
---@param R any
---@param G any
---@param B any
function _MTAX:ApplyColor(Slot, R, G, B)
    local Vehicle = self:Vehicle()
    if not Vehicle then
        return
    end

    Slot = self:Clamp(Slot, 1, 5, 1)
    R, G, B = self:Clamp(R, 0, 255, 0), self:Clamp(G, 0, 255, 0), self:Clamp(B, 0, 255, 0)

    if Slot == 5 then
        Server.headlight(false, R, G, B)
        return
    end

    local Values = { getVehicleColor(Vehicle, true) }
    for Index = 1, 12 do
        Values[Index] = Values[Index] or 255
    end

    local Offset = (Slot - 1) * 3
    Values[Offset + 1], Values[Offset + 2], Values[Offset + 3] = R, G, B

    Server.color(false, Values)
end

--- Environment

---@param Hour any
---@param Minute any
function _MTAX:SetTime(Hour, Minute)
    setTime(self:Clamp(Hour, 0, 23, 12), self:Clamp(Minute, 0, 59, 0))
end

---@param Frozen boolean
function _MTAX:FreezeTime(Frozen)
    self.Frozen = Frozen == true

    if setTimeFrozen then
        setTimeFrozen(self.Frozen)
        return
    end

    if self.Frozen then
        self.MinuteDuration = self.MinuteDuration or getMinuteDuration()
        setMinuteDuration(3600000)
    else
        setMinuteDuration(self.MinuteDuration or 1000)
        self.MinuteDuration = nil
    end
end

---@param Id any
function _MTAX:SetWeather(Id)
    if not tonumber(Id) then
        return self:Notify("error.invalid_weather")
    end

    setWeather(self:Clamp(Id, 0, 255, 0))
end

---@param Value any
---@return boolean
function _MTAX:SetGameSpeed(Value)
    Value = tonumber(Value)
    if not Value then
        return self:Notify("error.invalid_speed")
    end

    if not self:Allowed("gamespeed.enabled", "error.gamespeed_disabled") then
        return false
    end

    local Low = tonumber(self:Option("gamespeed.min")) or 0.25
    local High = tonumber(self:Option("gamespeed.max")) or 3

    if Value < Low or Value > High then
        return self:Notify("error.speed_range", {
            min = string.format("%.2f", Low),
            max = string.format("%.2f", High),
        })
    end

    setGameSpeed(Value)
    return true
end

---@param Key any
---@param Value any
function _MTAX:SetToggle(Key, Value)
    Value = Value == true

    if Key == "jetpack" then
        self:SetJetpack(Value)
    elseif Key == "bike" then
        setPedCanBeKnockedOffBike(localPlayer, Value)
    elseif Key == "frozen" then
        self:FreezeTime(Value)
    elseif Key == "warping" or Key == "knifing" or Key == "ghostmode" then
        Server.flag(false, Key, Value)
    end

    self.LastState = nil
end

--- Nui

---@param Name string
---@param Handler fun(Data: table): any
function _MTAX:Nui(Name, Handler)
    registerNuiCallback(Name, function(Data, Callback)
        local Reply = Handler(type(Data) == "table" and Data or {})
        Callback(type(Reply) == "table" and Reply or { ok = Reply ~= false })
    end)
end

function _MTAX:RegisterNui()
    self:Nui("ready", function()
        return { boot = self:BootPayload(), session = self.Session and self:SessionPayload() or false }
    end)

    self:Nui("windows", function(Data) self:SetWindows(Data.ids) end)
    self:Nui("key", function(Data) self:Toggle(tostring(Data.id or "")) end)
    self:Nui("labels", function(Data) Peers:SetLabel(Data.knife) end)

    --- Player
    self:Nui("skin", function(Data) return self:SetSkin(Data.id) end)
    self:Nui("animation", function(Data) return self:PlayAnimation(Data.block, Data.name) end)
    self:Nui("stopAnimation", function() Server.stopAnimation(false) end)
    self:Nui("weapon", function(Data) return self:GiveWeapon(Data.id, Data.ammo) end)
    self:Nui("stats", function(Data) return { values = self:StatValues(Data.ids) } end)
    self:Nui("stat", function(Data) return self:SetStat(Data.id, Data.value, Data.label) end)
    self:Nui("walk", function(Data) Server.walk(false, tonumber(Data.id) or 0) end)
    self:Nui("fight", function(Data) Server.fight(false, tonumber(Data.id) or 4) end)
    self:Nui("gravity", function(Data) return self:SetGravity(Data.value) end)
    self:Nui("suicide", function() self:Suicide() end)
    self:Nui("toggle", function(Data) self:SetToggle(Data.key, Data.value) end)

    self:Nui("clothes", function() return self:ClothesCatalog() end)
    self:Nui("wear", function(Data)
        if self:CanDress() then
            Server.wear(false, tostring(Data.texture or ""), tostring(Data.model or ""), tonumber(Data.type))
        end
    end)
    self:Nui("unwear", function(Data)
        if self:CanDress() then
            Server.unwear(false, tonumber(Data.type))
        end
    end)

    --- Players and places
    self:Nui("players", function() return { players = self:PlayerList() } end)
    self:Nui("blips", function() return self:Blips() end)
    self:Nui("warp", function(Data) return self:WarpTo(getPlayerFromName(tostring(Data.key or ""))) end)

    self:Nui("bookmark", function(Data) self:AddBookmark(Data.name) end)
    self:Nui("bookmarkDelete", function(Data) self:DeleteBookmark(Data.index) end)
    self:Nui("bookmarkGo", function(Data) return self:GoToBookmark(Data.index) end)

    self:Nui("interior", function(Data) return Teleport:Interior(Data.world, Data.x, Data.y, Data.z) end)
    self:Nui("teleport", function(Data) return Teleport:To(Data.x, Data.y, Data.z) end)
    self:Nui("ground", function(Data)
        local X, Y = tonumber(Data.x), tonumber(Data.y)
        local Ground = X and Y and tonumber(getGroundPosition(X, Y, 1000))
        return { z = (Ground and Ground > 0) and (Ground + 1.5) or 3 }
    end)

    --- Vehicle
    self:Nui("vehicle", function(Data) self:CreateVehicle(Data.id) end)
    self:Nui("repair", function() if self:Vehicle() then Server.repair(false) end end)
    self:Nui("flip", function() self:FlipVehicle() end)
    self:Nui("upgrades", function() return self:UpgradeList() end)
    self:Nui("upgrade", function(Data) self:ToggleUpgrade(Data.id) end)
    self:Nui("upgradesClear", function() if self:Vehicle() then Server.clearUpgrades(false) end end)
    self:Nui("paintjob", function(Data) if self:Vehicle() then Server.paintjob(false, tonumber(Data.id)) end end)
    self:Nui("lights", function(Data) if self:Vehicle() then Server.lights(false, tonumber(Data.mode) or 0) end end)
    self:Nui("colorGet", function(Data) return { rgb = self:VehicleColor(Data.slot) or false } end)
    self:Nui("color", function(Data) self:ApplyColor(Data.slot, Data.r, Data.g, Data.b) end)

    --- Environment
    self:Nui("time", function(Data) self:SetTime(Data.hour, Data.minute) end)
    self:Nui("weather", function(Data) self:SetWeather(Data.id) end)
    self:Nui("speed", function(Data) return self:SetGameSpeed(Data.value) end)
end

--- Keys and commands

function _MTAX:RegisterKeys()
    bindKey(Config.Keys.Panel, "down", function() self:Toggle("main") end)
    bindKey(Config.Keys.Map, "down", function() self:Toggle("map") end)

    bindKey(Config.Keys.Jetpack, "down", function()
        if not self.Focused then
            self:SetJetpack()
        end
    end)

    bindKey(Config.Keys.StopAnim, "down", function()
        if not self.Focused then
            self:StopAnimation()
        end
    end)
end

---@param Names string[]
---@param Handler function
function _MTAX:Command(Names, Handler)
    for _, Name in ipairs(Names) do
        addCommandHandler(Name, function(_, ...) Handler(...) end)
    end
end

function _MTAX:RegisterCommands()
    self:Command({ "fr" }, function() self:Toggle("main") end)
    self:Command({ "flip", "f" }, function() self:FlipVehicle() end)

    self:Command({ "setpos", "sp" }, function(X, Y, Z, Rotation)
        if not (X or Y or Z) then
            self:OpenTool("map")
            return
        end

        local PX, PY, PZ = getElementPosition(localPlayer)
        if not Teleport:To(tonumber(X) or PX, tonumber(Y) or PY, tonumber(Z) or PZ) then
            return
        end

        local Element = getPedOccupiedVehicle(localPlayer) or localPlayer
        local RX, RY, RZ = getElementRotation(Element)
        setElementRotation(Element, RX, RY, tonumber(Rotation) or RZ)
    end)

    self:Command({ "getpos", "gp" }, function(Part)
        local Player = self:FindPlayer(Part) or localPlayer
        local X, Y, Z = self:PlayerPosition(Player)

        if not X then
            self:Notify("error.player_no_position")
            return
        end

        local Text = string.format("%.5f, %.5f, %.5f", X, Y, Z)
        setClipboard(Text)
        outputChatBox(string.format("%s: {%s}", self:PlayerName(Player), Text), 34, 197, 94)
        self:Notify("notify.position_copied", nil, "success")
    end)

    self:Command({ "warpto", "wt" }, function(Part)
        local Player = self:FindPlayer(Part)
        if Player and Player ~= localPlayer then self:WarpTo(Player) else self:OpenTool("players") end
    end)

    self:Command({ "settime", "st" }, function(Hour, Minute)
        if not tonumber(Hour) then
            self:OpenTool("time")
            return
        end

        local _, Current = getTime()
        self:SetTime(Hour, tonumber(Minute) or Current)
    end)

    self:Command({ "setweather", "sw" }, function(Id)
        if tonumber(Id) then self:SetWeather(Id) else self:OpenTool("weather") end
    end)

    self:Command({ "setgamespeed", "speed" }, function(Value)
        if tonumber(Value) then self:SetGameSpeed(Value) else self:OpenTool("gamespeed") end
    end)
end

Main = _MTAX:New()

Main:Init()

--- Tunnel

Client.notify = function(Key, Vars, Kind)
    Main:Notify(tostring(Key or ""), type(Vars) == "table" and Vars or {}, Kind)
end

Client.open = function(Id)
    Main:OpenTool(tostring(Id or ""))
end

Client.options = function(Options)
    if type(Options) ~= "table" then
        return
    end

    Main.Options = Options
    sendNuiMessage({ action = "options", data = Options })
end

Client.flag = function(Player, Key, Value)
    Peers:Set(Player, Key, Value)
end

Client.gravity = function(Value)
    Main.Gravity = tonumber(Value) or Main.Gravity
end

--- Exports

---@param State? boolean
---@return boolean
function openFreeroam(State)
    if State == nil then
        Main:Toggle("main")
        return not Main.Windows.main
    end

    sendNuiMessage({ action = State and "open" or "close", data = "main" })
    return State == true
end
