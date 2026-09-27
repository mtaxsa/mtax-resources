---@alias Element userdata

local NORMAL_GRAVITY = 0.008
local SAWNOFF_LOCK = 3000
local WORLD_LIMIT = 100000

local EMPTY_PED_SLOTS = {
    [3] = true, [4] = true, [5] = true, [6] = true, [8] = true,
    [42] = true, [65] = true, [74] = true, [86] = true, [119] = true,
    [149] = true, [208] = true, [268] = true, [273] = true, [289] = true,
}

local FIGHT_STYLES = { [4] = true, [5] = true, [6] = true, [7] = true, [15] = true, [16] = true }

-- Per-player switches and the option that lets players turn them on.
local FLAGS = {
    warping   = "gui.disablewarp",
    knifing   = "gui.disableknife",
    ghostmode = "gui.antiram",
}

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Ready = {}
    self.Flags = {}
    self.Throttles = {}
    self.Sawnoff = {}
    self.LastVehicle = {}
    self.ClothesGroups = nil
    self.ValidSkins = self:LoadValidSkins()

    --- Add Events
    addEventHandler("onPlayerQuit", root, function() local Source = source; self:PlayerQuit(Source) end)

    self:RegisterCommands()
end

--- Helpers

---@param Element any
---@return boolean
function _MTAX:IsPlayer(Element)
    return isElement(Element) and getElementType(Element) == "player"
end

---@param Player Element
---@return string
function _MTAX:Name(Player)
    local Name = getPlayerName(Player) or "?"

    if Options:Get("removeHex") then
        Name = Name:gsub("#%x%x%x%x%x%x", "")
    end

    return Name
end

-- Players that joined but never spawned sit at the default camera spot or at the origin.
---@param Player Element
---@return boolean
function _MTAX:IsSpawned(Player)
    local X, Y, Z = getElementPosition(Player)
    if type(X) ~= "number" then
        return false
    end

    if math.floor(X) == 132 and math.floor(Y) == -68 then
        return false
    end

    return not (math.abs(X) < 2 and math.abs(Y) < 2 and Z < 1)
end

---@param Player Element
---@return boolean
function _MTAX:IsDown(Player)
    return isPedDead(Player) or not self:IsSpawned(Player)
end

---@param Value any
---@param Low number
---@param High number
---@return number|nil
function _MTAX:Integer(Value, Low, High)
    Value = tonumber(Value)
    if not Value or Value ~= Value then
        return nil
    end

    Value = math.floor(Value)
    if Value < Low or Value > High then
        return nil
    end

    return Value
end

---@param Value any
---@return number|nil
function _MTAX:Coordinate(Value)
    Value = tonumber(Value)
    if not Value or Value ~= Value or math.abs(Value) > WORLD_LIMIT then
        return nil
    end

    return Value
end

---@param Player Element
---@param Name string
---@param Delay number
---@return boolean
function _MTAX:Throttle(Player, Name, Delay)
    local Now = getTickCount()
    local List = self.Throttles[Player] or {}
    self.Throttles[Player] = List

    if List[Name] and Now - List[Name] < Delay then
        return false
    end

    List[Name] = Now
    return true
end

---@param Player Element
---@param Key string
---@param Vars? table
---@param Kind? string
function _MTAX:Notify(Player, Key, Vars, Kind)
    if not self.Ready[Player] then
        return
    end

    Client.notify(false, Player, Key, Vars or {}, Kind or "error")
end

---@param Player Element
---@param Option string
---@param Message? string
---@return boolean
function _MTAX:Allowed(Player, Option, Message)
    if Options:Get(Option) then
        return true
    end

    self:Notify(Player, Message or "error.action_not_allowed")
    return false
end

---@param Player Element
---@param Driver? boolean
---@return Element|nil
function _MTAX:Vehicle(Player, Driver)
    local Vehicle = getPedOccupiedVehicle(Player)

    if not Vehicle then
        self:Notify(Player, "error.need_vehicle")
        return nil
    end

    if Driver and getVehicleController(Vehicle) ~= Player then
        self:Notify(Player, "error.driver_only")
        return nil
    end

    return Vehicle
end

---@return Element[]
function _MTAX:ReadyPlayers()
    local Players = {}

    for Player in pairs(self.Ready) do
        if isElement(Player) then
            Players[#Players + 1] = Player
        end
    end

    return Players
end

---@param Player Element
---@param Id string
function _MTAX:Open(Player, Id)
    if self.Ready[Player] then
        Client.open(false, Player, Id)
    end
end

--- Session

---@param Player Element
---@return table, table[], table[], number
function _MTAX:Session(Player)
    self.Ready[Player] = true

    local Flags = {}
    for Other, Set in pairs(self.Flags) do
        if isElement(Other) then
            Flags[#Flags + 1] = {
                player    = Other,
                warping   = Set.warping == true,
                knifing   = Set.knifing == true,
                ghostmode = Set.ghostmode == true,
            }
        end
    end

    return Options:Resolved(), Bookmarks:Get(Player), Flags, getPedGravity(Player)
end

---@param Player Element
function _MTAX:PlayerQuit(Player)
    if isTimer(self.Sawnoff[Player]) then
        killTimer(self.Sawnoff[Player])
    end

    self.Ready[Player] = nil
    self.Flags[Player] = nil
    self.Throttles[Player] = nil
    self.Sawnoff[Player] = nil
    self.LastVehicle[Player] = nil

    Vehicles:Clear(Player)
end

function _MTAX:PushOptions()
    local Players = self:ReadyPlayers()
    if #Players > 0 then
        Client.options(false, Players, Options:Resolved())
    end
end

--- Ped

---@return table<number, boolean>|nil
function _MTAX:LoadValidSkins()
    if type(getValidPedModels) ~= "function" then
        return nil
    end

    local Ok, List = pcall(getValidPedModels)
    if not Ok or type(List) ~= "table" or #List == 0 then
        return nil
    end

    local Set = {}
    for _, Id in ipairs(List) do
        Set[tonumber(Id) or -1] = true
    end

    return Set
end

---@param Id number
---@return boolean
function _MTAX:IsWearable(Id)
    if EMPTY_PED_SLOTS[Id] then
        return false
    end

    if self.ValidSkins then
        return self.ValidSkins[Id] == true
    end

    return Id >= 0 and Id <= 312
end

---@param Player Element
---@param Id any
function _MTAX:SetSkin(Player, Id)
    if not self:Allowed(Player, "setskin") then
        return
    end

    local Skin = self:Integer(Id, 0, 65535)
    if not Skin or not self:IsWearable(Skin) then
        self:Notify(Player, "error.skin_not_wearable", { id = tostring(Id) })
        return
    end

    if getElementModel(Player) == Skin then
        return
    end

    if not self:IsDown(Player) then
        setElementModel(Player, Skin)
        return
    end

    local X, Y, Z = getElementPosition(Player)
    if not self:IsSpawned(Player) then
        X, Y, Z = 0, 0, 3
    end

    local _, _, Rotation = getElementRotation(Player)
    local Interior = getElementInterior(Player)

    spawnPlayer(Player, X, Y, Z, Rotation, Skin, Interior, getElementDimension(Player))
    setCameraInterior(Player, Interior)
    setCameraTarget(Player, Player)
end

---@param Player Element
---@param Block any
---@param Name any
function _MTAX:SetAnimation(Player, Block, Name)
    if not self:Allowed(Player, "anim") then
        return
    end

    if type(Block) ~= "string" or type(Name) ~= "string" or #Block > 64 or #Name > 64 then
        return
    end

    setPedAnimation(Player, Block, Name, -1, true, true)
end

---@param Player Element
function _MTAX:StopAnimation(Player)
    setPedAnimation(Player, false)
end

---@param Player Element
---@param Id any
---@param Ammo any
function _MTAX:GiveWeapon(Player, Id, Ammo)
    if not self:Allowed(Player, "weapons.enabled") then
        return
    end

    local Weapon = self:Integer(Id, 1, 46)
    if not Weapon then
        self:Notify(Player, "error.invalid_weapon")
        return
    end

    if Options:Contains(Options:Get("weapons.disallowed"), Weapon) then
        self:Notify(Player, "error.weapon_not_allowed", { weapon = getWeaponNameFromID(Weapon) or tostring(Weapon) })
        return
    end

    giveWeapon(Player, Weapon, math.max(1, math.min(9999, math.floor(tonumber(Ammo) or 500))), true)

    if Weapon == 26 then
        self:LockSawnoff(Player)
    end
end

-- Stops the instant-fire trick right after receiving a sawn-off.
---@param Player Element
function _MTAX:LockSawnoff(Player)
    if self.Sawnoff[Player] then
        return
    end

    setControlState(Player, "aim_weapon", false)
    setControlState(Player, "fire", false)
    toggleControl(Player, "fire", false)
    reloadPedWeapon(Player)

    self.Sawnoff[Player] = setTimer(function()
        self.Sawnoff[Player] = nil

        if isElement(Player) then
            toggleControl(Player, "fire", true)
        end
    end, SAWNOFF_LOCK, 1)
end

---@param Player Element
---@param Id any
---@param Value any
function _MTAX:SetStat(Player, Id, Value)
    if not self:Allowed(Player, "stats") then
        return
    end

    local Stat = self:Integer(Id, 0, 400)
    if not Stat then
        return
    end

    setPedStat(Player, Stat, math.max(0, math.min(1000, math.floor(tonumber(Value) or 1000))))
end

---@param Player Element
---@param Id any
function _MTAX:SetWalkStyle(Player, Id)
    if not self:Allowed(Player, "walkstyle") then
        return
    end

    local Style = self:Integer(Id, 0, 200)
    if Style then
        setPedWalkingStyle(Player, Style)
    end
end

---@param Player Element
---@param Id any
function _MTAX:SetFightStyle(Player, Id)
    if not self:Allowed(Player, "setstyle") then
        return
    end

    local Style = self:Integer(Id, 0, 16)
    if Style and FIGHT_STYLES[Style] then
        setPedFightingStyle(Player, Style)
    end
end

---@param Player Element
---@param Value any
---@return number
function _MTAX:SetGravity(Player, Value)
    Value = tonumber(Value)

    if Value and Value == Value and self:Allowed(Player, "gravity.enabled") then
        local Low = tonumber(Options:Get("gravity.min")) or 0
        local High = tonumber(Options:Get("gravity.max")) or 0.1

        if Value < Low then
            self:Notify(Player, "error.gravity_min", { value = string.format("%.5f", Low) })
        elseif Value > High then
            self:Notify(Player, "error.gravity_max", { value = string.format("%.5f", High) })
        else
            setPedGravity(Player, Value)
        end
    end

    return getPedGravity(Player)
end

---@param Player Element
---@param Value any
function _MTAX:SetAlpha(Player, Value)
    if not self:Allowed(Player, "alpha") then
        return
    end

    local Alpha = self:Integer(Value, 0, 255)
    if Alpha then
        setElementAlpha(Player, Alpha)
    end
end

---@param Player Element
---@param Enabled boolean
function _MTAX:SetJetpack(Player, Enabled)
    if not Enabled then
        setPedWearingJetpack(Player, false)
        return
    end

    if not self:Allowed(Player, "jetpack", "error.jetpack_disabled") then
        return
    end

    if math.abs(getPedGravity(Player) - NORMAL_GRAVITY) > 0.0001 then
        self:Notify(Player, "error.jetpack_gravity")
        return
    end

    setPedWearingJetpack(Player, true)
end

---@param Player Element
function _MTAX:Kill(Player)
    if not self:Allowed(Player, "kill", "error.suicide_disabled") then
        return
    end

    if not self:IsDown(Player) then
        killPed(Player, Player)
    end
end

--- Clothes

---@return table[]
function _MTAX:ClothesCatalog()
    if self.ClothesGroups then
        return self.ClothesGroups
    end

    local Groups = {}

    for Type = 0, 17 do
        local Items = {}
        local Index = 0
        local Texture, Model = getClothesByTypeIndex(Type, Index)

        while Texture do
            Items[#Items + 1] = { texture = Texture, model = Model }
            Index = Index + 1
            Texture, Model = getClothesByTypeIndex(Type, Index)
        end

        Groups[#Groups + 1] = { type = Type, name = getClothesTypeName(Type) or tostring(Type), items = Items }
    end

    self.ClothesGroups = Groups
    return Groups
end

---@param Player Element
---@return boolean
function _MTAX:CanDress(Player)
    if not self:Allowed(Player, "clothes") then
        return false
    end

    if getElementModel(Player) ~= 0 then
        self:Notify(Player, "error.cj_skin_required")
        return false
    end

    return true
end

---@param Player Element
---@param Texture any
---@param Model any
---@param Type any
function _MTAX:AddClothes(Player, Texture, Model, Type)
    Type = self:Integer(Type, 0, 17)

    if not Type or type(Texture) ~= "string" or type(Model) ~= "string" or #Texture > 32 or #Model > 32 then
        return
    end

    if self:CanDress(Player) then
        addPedClothes(Player, Texture, Model, Type)
    end
end

---@param Player Element
---@param Type any
function _MTAX:RemoveClothes(Player, Type)
    Type = self:Integer(Type, 0, 17)

    if Type and self:CanDress(Player) then
        removePedClothes(Player, Type)
    end
end

--- Vehicles

---@param Player Element
---@param Id any
function _MTAX:SpawnVehicle(Player, Id)
    if not self:Allowed(Player, "createvehicle", "error.vehicle_creation_disabled") then
        return
    end

    local Model = self:Integer(Id, 400, 611)
    local Name = Model and getVehicleNameFromModel(Model)

    if not Name or Name == "" then
        self:Notify(Player, "error.invalid_model")
        return
    end

    if Options:Contains(Options:Get("vehicles.disallowed"), Model) then
        self:Notify(Player, "error.vehicle_not_allowed", { vehicle = Name })
        return
    end

    if not self:IsSpawned(Player) then
        self:Notify(Player, "error.need_world_position")
        return
    end

    if not self:Throttle(Player, "vehicle", 500) then
        return
    end

    local Element = getPedOccupiedVehicle(Player) or Player
    local X, Y, Z = getElementPosition(Element)
    local _, _, Rotation = getElementRotation(Element)
    local Angle = math.rad(Rotation)

    if not Vehicles:Spawn(Player, Model, X + math.cos(Angle) * 3, Y + math.sin(Angle) * 3, Z + 2, Rotation) then
        self:Notify(Player, "error.vehicle_create_failed")
    end
end

---@param Player Element
function _MTAX:RepairVehicle(Player)
    if not self:Allowed(Player, "repair") then
        return
    end

    local Vehicle = self:Vehicle(Player)
    if Vehicle then
        fixVehicle(Vehicle)
    end
end

---@param Player Element
---@param Colors any
function _MTAX:SetVehicleColor(Player, Colors)
    if type(Colors) ~= "table" then
        return
    end

    local Values = {}
    for Index = 1, 12 do
        Values[Index] = self:Integer(Colors[Index], 0, 255)
        if not Values[Index] then
            return
        end
    end

    local Vehicle = self:Vehicle(Player)
    if Vehicle then
        setVehicleColor(Vehicle, unpack(Values, 1, 12))
    end
end

---@param Player Element
---@param R any
---@param G any
---@param B any
function _MTAX:SetHeadlightColor(Player, R, G, B)
    R, G, B = self:Integer(R, 0, 255), self:Integer(G, 0, 255), self:Integer(B, 0, 255)
    if not R or not G or not B then
        return
    end

    local Vehicle = self:Vehicle(Player)
    if Vehicle then
        setVehicleHeadLightColor(Vehicle, R, G, B)
    end
end

---@param Player Element
---@param Mode any
function _MTAX:SetLights(Player, Mode)
    if not self:Allowed(Player, "lights") then
        return
    end

    Mode = self:Integer(Mode, 0, 2)
    local Vehicle = Mode and self:Vehicle(Player)

    if Vehicle then
        setVehicleOverrideLights(Vehicle, Mode)
    end
end

---@param Player Element
---@param Id any
function _MTAX:SetPaintjob(Player, Id)
    if not self:Allowed(Player, "paintjob") then
        return
    end

    Id = self:Integer(Id, 0, 3)
    if not Id then
        self:Notify(Player, "error.invalid_paintjob")
        return
    end

    local Vehicle = self:Vehicle(Player)
    if Vehicle then
        setVehiclePaintjob(Vehicle, Id)
    end
end

---@param Player Element
---@param Id any
---@param Install boolean
function _MTAX:SetUpgrade(Player, Id, Install)
    if not self:Allowed(Player, "upgrades") then
        return
    end

    Id = self:Integer(Id, 1000, 1193)
    local Vehicle = Id and self:Vehicle(Player)

    if not Vehicle then
        return
    end

    if Install then
        addVehicleUpgrade(Vehicle, Id)
    else
        removeVehicleUpgrade(Vehicle, Id)
    end
end

---@param Player Element
function _MTAX:ClearUpgrades(Player)
    if not self:Allowed(Player, "upgrades") then
        return
    end

    local Vehicle = self:Vehicle(Player)
    if not Vehicle then
        return
    end

    for _, Id in ipairs(getVehicleUpgrades(Vehicle) or {}) do
        removeVehicleUpgrade(Vehicle, Id)
    end
end

--- Position

---@param Player Element
---@param X any
---@param Y any
---@param Z any
function _MTAX:MoveTo(Player, X, Y, Z)
    X, Y, Z = self:Coordinate(X), self:Coordinate(Y), self:Coordinate(Z)
    if not X or not Y or not Z then
        return
    end

    local Vehicle = getPedOccupiedVehicle(Player)
    if not Vehicle then
        setElementPosition(Player, X, Y, Z)
        return
    end

    if getVehicleController(Vehicle) ~= Player then
        self:Notify(Player, "error.driver_teleport_only")
        return
    end

    self.LastVehicle[Player] = Vehicle
    setElementPosition(Vehicle, X, Y, Z)
end

-- Puts the driver back in the car they just teleported with, if the move threw them out.
---@param Player Element
---@param Vehicle any
function _MTAX:Reenter(Player, Vehicle)
    if Vehicle ~= self.LastVehicle[Player] or not isElement(Vehicle) then
        return
    end

    self.LastVehicle[Player] = nil

    if not getPedOccupiedVehicle(Player) then
        self:WarpIntoVehicle(Player, Vehicle)
    end
end

---@param Player Element
---@param Visible boolean
function _MTAX:FadePassengers(Player, Visible)
    local Vehicle = getPedOccupiedVehicle(Player)
    if not Vehicle or getVehicleController(Vehicle) ~= Player then
        return
    end

    for Seat = 0, getVehicleMaxPassengers(Vehicle) or 0 do
        local Occupant = getVehicleOccupant(Vehicle, Seat)
        if Occupant then
            fadeCamera(Occupant, Visible == true)
        end
    end
end

---@param Element Element
---@param Interior number
---@param Dimension number
function _MTAX:Place(Element, Interior, Dimension)
    setElementInterior(Element, Interior)
    setElementDimension(Element, Dimension)

    if getElementType(Element) == "player" then
        setCameraInterior(Element, Interior)
    end
end

---@param Player Element
---@param Interior any
---@param Dimension any
function _MTAX:SetWorld(Player, Interior, Dimension)
    Interior = self:Integer(Interior, 0, 255)
    Dimension = Dimension == nil and getElementDimension(Player) or self:Integer(Dimension, 0, 65535)

    if not Interior or not Dimension then
        return
    end

    local Vehicle = getPedOccupiedVehicle(Player)
    if not Vehicle then
        self:Place(Player, Interior, Dimension)
        return
    end

    if getVehicleController(Vehicle) ~= Player then
        self:Notify(Player, "error.driver_interior_only")
        return
    end

    self:Place(Vehicle, Interior, Dimension)

    for Seat = 0, getVehicleMaxPassengers(Vehicle) or 0 do
        local Occupant = getVehicleOccupant(Vehicle, Seat)
        if Occupant then
            self:Place(Occupant, Interior, Dimension)
        end
    end
end

---@param Player Element
---@param Vehicle Element
---@return boolean
function _MTAX:WarpIntoVehicle(Player, Vehicle)
    if Options:Contains(Options:Get("vehicles.disallowed_warp"), getElementModel(Vehicle)) then
        self:Notify(Player, "error.vehicle_warp_blocked")
        return false
    end

    if getPedOccupiedVehicle(Player) then
        self:Notify(Player, "error.exit_vehicle_first")
        return false
    end

    local Interior = getElementInterior(Vehicle)
    local Dimension = getElementDimension(Vehicle)

    for Seat = 0, getVehicleMaxPassengers(Vehicle) or 0 do
        if not getVehicleOccupant(Vehicle, Seat) then
            if self:IsDown(Player) then
                local X, Y, Z = getElementPosition(Vehicle)
                spawnPlayer(Player, X + 4, Y, Z + 1, 0, getElementModel(Player), Interior, Dimension)
            end

            self:Place(Player, Interior, Dimension)
            warpPedIntoVehicle(Player, Vehicle, Seat)
            return true
        end
    end

    local Driver = getVehicleController(Vehicle)
    self:Notify(Player, "error.no_free_seats", { player = Driver and self:Name(Driver) or "?" })
    return false
end

---@param Player Element
---@param Target any
---@return number?, number?, number?, number?, number?, number?
function _MTAX:WarpTo(Player, Target)
    if not self:IsPlayer(Target) or Target == Player then
        self:Notify(Player, "error.choose_other_player")
        return
    end

    if not self:Allowed(Player, "warp", "error.warp_disabled") then
        return
    end

    if self.Flags[Target] and self.Flags[Target].warping then
        self:Notify(Player, "error.player_blocked_warp")
        return
    end

    if not self:Throttle(Player, "warp", 600) then
        return
    end

    local Vehicle = getPedOccupiedVehicle(Target)
    if Vehicle and not getPedOccupiedVehicle(Player) and not self:IsDown(Player) then
        self:Notify(Player, "notify.finding_seat", nil, "info")
        self:WarpIntoVehicle(Player, Vehicle)
        return
    end

    if not self:IsSpawned(Target) then
        self:Notify(Player, "error.player_no_position")
        return
    end

    local Element = Vehicle or Target
    local X, Y, Z = getElementPosition(Element)
    local _, _, Rotation = getElementRotation(Element)

    return X, Y, Z, Rotation, getElementInterior(Target), getElementDimension(Target)
end

-- Positions of everyone else, for the map and the player list (far players are not streamed in).
---@param Player Element
---@return table[]|nil
function _MTAX:Positions(Player)
    if not self:Throttle(Player, "positions", 400) then
        return nil
    end

    local List = {}

    for _, Other in ipairs(getElementsByType("player")) do
        if Other ~= Player and self:IsSpawned(Other) then
            local X, Y, Z = getElementPosition(Other)
            local Vehicle = getPedOccupiedVehicle(Other)

            List[#List + 1] = {
                player    = Other,
                x         = X,
                y         = Y,
                z         = Z,
                vehicle   = Vehicle and getVehicleName(Vehicle) or false,
                interior  = getElementInterior(Other),
                dimension = getElementDimension(Other),
            }
        end
    end

    return List
end

--- Flags

---@param Player Element
---@param Key any
---@param Value any
function _MTAX:SetFlag(Player, Key, Value)
    local Option = FLAGS[Key]
    if not Option then
        return
    end

    Value = Value == true
    if Value and not self:Allowed(Player, Option) then
        return
    end

    self.Flags[Player] = self.Flags[Player] or {}
    self.Flags[Player][Key] = Value

    local Players = self:ReadyPlayers()
    if #Players > 0 then
        Client.flag(false, Players, Player, Key, Value)
    end
end

--- Commands

---@param Names string[]
---@param Handler function
function _MTAX:Command(Names, Handler)
    local Guarded = function(Player, _, ...)
        if self:IsPlayer(Player) then
            Handler(Player, ...)
        end
    end

    for _, Name in ipairs(Names) do
        addCommandHandler(Name, Guarded)
    end
end

function _MTAX:RegisterCommands()
    self:Command({ "setskin", "ss" }, function(Player, Id)
        if tonumber(Id) then self:SetSkin(Player, Id) else self:Open(Player, "skins") end
    end)

    self:Command({ "give", "wp" }, function(Player, Weapon, Ammo)
        local Id = tonumber(Weapon) or (Weapon and getWeaponIDFromName(Weapon))
        if Id then self:GiveWeapon(Player, Id, Ammo) else self:Open(Player, "weapons") end
    end)

    self:Command({ "createvehicle", "cv" }, function(Player, ...)
        local Name = table.concat({ ... }, " ")
        local Id = tonumber(Name) or (Name ~= "" and getVehicleModelFromName(Name))
        if Id then self:SpawnVehicle(Player, Id) else self:Open(Player, "vehicles") end
    end)

    self:Command({ "repair", "rp" }, function(Player) self:RepairVehicle(Player) end)
    self:Command({ "jetpack", "jp" }, function(Player) self:SetJetpack(Player, not isPedWearingJetpack(Player)) end)
    self:Command({ "kill" }, function(Player) self:Kill(Player) end)
    self:Command({ "stopanim" }, function(Player) self:StopAnimation(Player) end)

    self:Command({ "anim" }, function(Player, Block, Name)
        if Block and Name then self:SetAnimation(Player, Block, Name) else self:Open(Player, "animations") end
    end)

    self:Command({ "setstyle" }, function(Player, Id)
        if tonumber(Id) then self:SetFightStyle(Player, Id) else self:Open(Player, "fightstyles") end
    end)

    self:Command({ "setgravity", "grav" }, function(Player, Value)
        if not tonumber(Value) then
            self:Open(Player, "gravity")
            return
        end

        local Gravity = self:SetGravity(Player, Value)
        if self.Ready[Player] then
            Client.gravity(false, Player, Gravity)
        end
    end)

    self:Command({ "alpha", "ap" }, function(Player, Value)
        if tonumber(Value) then self:SetAlpha(Player, Value) else self:Notify(Player, "help.alpha", nil, "info") end
    end)

    self:Command({ "addupgrade", "au" }, function(Player, Id)
        if tonumber(Id) then self:SetUpgrade(Player, Id, true) else self:Open(Player, "upgrades") end
    end)

    self:Command({ "removeupgrade", "ru" }, function(Player, Id)
        if tonumber(Id) then self:SetUpgrade(Player, Id, false) else self:Open(Player, "upgrades") end
    end)

    self:Command({ "color", "cl" }, function(Player, ...)
        local Args = { ... }
        local Vehicle = self:Vehicle(Player)

        if not Vehicle then
            return
        end

        if #Args == 0 then
            self:Open(Player, "vehiclecolor")
            return
        end

        local Values = { getVehicleColor(Vehicle, true) }
        for Index = 1, 12 do
            Values[Index] = tonumber(Args[Index]) or Values[Index] or 255
        end

        self:SetVehicleColor(Player, Values)
    end)

    self:Command({ "paintjob", "pj" }, function(Player, Id)
        if tonumber(Id) then self:SetPaintjob(Player, Id) else self:Open(Player, "paintjobs") end
    end)

    self:Command({ "addclothes", "ac" }, function(Player, Type, Model, Texture)
        if tonumber(Type) and Model and Texture then
            self:AddClothes(Player, Texture, Model, Type)
        else
            self:Open(Player, "clothes")
        end
    end)

    self:Command({ "removeclothes", "rc" }, function(Player, Type)
        if tonumber(Type) then self:RemoveClothes(Player, Type) else self:Open(Player, "clothes") end
    end)

    addCommandHandler("frconfig", function(Player, _, Key, ...) self:ConfigCommand(Player, Key, ...) end)
end

---@param Player Element
---@return boolean
function _MTAX:CanConfigure(Player)
    if isElement(Player) and getElementType(Player) == "console" then
        return true
    end

    local Ok, Allowed = pcall(function()
        return exports["acls"]:hasObjectPermissionTo(Player, Config.SettingsPermission, false)
    end)

    return Ok and Allowed == true
end

---@param Player Element
---@param Key? string
function _MTAX:ConfigCommand(Player, Key, ...)
    if not self:CanConfigure(Player) then
        self:Notify(Player, "config.no_permission")
        return
    end

    if not Key then
        local Empty = true

        for Name, Value in pairs(Options.Overrides) do
            Empty = false
            outputChatBox(string.format("  %s = %s", Name, tostring(Value)), Player, 200, 200, 200)
        end

        if Empty then
            outputChatBox("  (no overrides, everything is default)", Player, 200, 200, 200)
        end

        outputChatBox("Usage: /frconfig <key> [value|default]", Player, 200, 200, 200)
        return
    end

    local Value = table.concat({ ... }, " ")

    if Value == "" then
        outputChatBox(string.format("%s = %s", Key, tostring(Options:Get(Key))), Player, 255, 194, 14)
        return
    end

    if type(Options:Default(Key)) == "table" then
        outputChatBox(string.format("%s is a list; edit %s by hand.", Key, Config.SettingsFile), Player, 239, 68, 68)
        return
    end

    if not Options:Set(Key, Value ~= "default" and Value or nil) then
        outputChatBox(string.format("Could not write %s.", Config.SettingsFile), Player, 239, 68, 68)
        return
    end

    self:PushOptions()
    outputChatBox(string.format("%s = %s", Key, tostring(Options:Get(Key))), Player, 34, 197, 94)
end

local Main = _MTAX:New()

Main:Init()

--- Tunnel

Server.ready = function()
    if not Main:IsPlayer(client) then
        return false
    end

    return Main:Session(client)
end

Server.skin = function(Id) Main:SetSkin(client, Id) end
Server.animation = function(Block, Name) Main:SetAnimation(client, Block, Name) end
Server.stopAnimation = function() Main:StopAnimation(client) end
Server.weapon = function(Id, Ammo) Main:GiveWeapon(client, Id, Ammo) end
Server.stat = function(Id, Value) Main:SetStat(client, Id, Value) end
Server.walk = function(Id) Main:SetWalkStyle(client, Id) end
Server.fight = function(Id) Main:SetFightStyle(client, Id) end
Server.gravity = function(Value) return Main:SetGravity(client, Value) end
Server.alpha = function(Value) Main:SetAlpha(client, Value) end
Server.jetpack = function(Enabled) Main:SetJetpack(client, Enabled == true) end
Server.kill = function() Main:Kill(client) end

Server.clothes = function() return Main:ClothesCatalog() end
Server.wear = function(Texture, Model, Type) Main:AddClothes(client, Texture, Model, Type) end
Server.unwear = function(Type) Main:RemoveClothes(client, Type) end

Server.vehicle = function(Model) Main:SpawnVehicle(client, Model) end
Server.repair = function() Main:RepairVehicle(client) end
Server.color = function(Colors) Main:SetVehicleColor(client, Colors) end
Server.headlight = function(R, G, B) Main:SetHeadlightColor(client, R, G, B) end
Server.lights = function(Mode) Main:SetLights(client, Mode) end
Server.paintjob = function(Id) Main:SetPaintjob(client, Id) end
Server.upgrade = function(Id, Install) Main:SetUpgrade(client, Id, Install == true) end
Server.clearUpgrades = function() Main:ClearUpgrades(client) end

Server.moveTo = function(X, Y, Z) Main:MoveTo(client, X, Y, Z) end
Server.reenter = function(Vehicle) Main:Reenter(client, Vehicle) end
Server.fade = function(Visible) Main:FadePassengers(client, Visible) end
Server.world = function(Interior, Dimension) Main:SetWorld(client, Interior, Dimension) end
Server.warpTo = function(Target) return Main:WarpTo(client, Target) end
Server.positions = function() return Main:Positions(client) end

Server.flag = function(Key, Value) Main:SetFlag(client, Key, Value) end

Server.addBookmark = function(Name)
    local List, Error, Vars = Bookmarks:Add(client, Name)
    if not List then
        Main:Notify(client, Error, Vars)
        return nil
    end

    return List
end

Server.deleteBookmark = function(Index) return Bookmarks:Delete(client, Index) end
