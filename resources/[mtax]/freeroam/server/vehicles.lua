---@alias Element userdata

local NORMAL_GRAVITY = 0.008

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Owned = {}
    self.Data = {}
    self.SavedGravity = {}

    --- Add Events
    addEventHandler("onVehicleEnter", root, function(Player) local Source = source; self:Enter(Source, Player) end)
    addEventHandler("onVehicleExit", root, function(Player) local Source = source; self:Exit(Source, Player) end)
    addEventHandler("onVehicleExplode", root, function() local Source = source; self:Explode(Source) end)
    addEventHandler("onElementDestroy", root, function() local Source = source; self:Forget(Source) end)
end

---@param Player Element
---@param Model number
---@param X number
---@param Y number
---@param Z number
---@param Rotation number
---@return Element|false
function _MTAX:Spawn(Player, Model, X, Y, Z, Rotation)
    local List = self.Owned[Player] or {}
    self.Owned[Player] = List

    local Max = math.max(1, tonumber(Options:Get("vehicles.maxperplayer")) or 1)
    while #List >= Max do
        self:Unload(List[1])
    end

    local Vehicle = createVehicle(Model, X, Y, Z, 0, 0, Rotation)
    if not isElement(Vehicle) then
        return false
    end

    setElementInterior(Vehicle, getElementInterior(Player))
    setElementDimension(Vehicle, getElementDimension(Player))

    if getVehicleType(Vehicle) == "Bike" then
        setElementVelocity(Vehicle, 0, 0, -0.01)
    end

    List[#List + 1] = Vehicle
    self.Data[Vehicle] = { Owner = Player }
    return Vehicle
end

---@param Vehicle Element
function _MTAX:Forget(Vehicle)
    local Data = self.Data[Vehicle]
    if not Data then
        return
    end

    self.Data[Vehicle] = nil

    if isTimer(Data.Timer) then
        killTimer(Data.Timer)
    end

    local List = self.Owned[Data.Owner]
    for Index = #(List or {}), 1, -1 do
        if List[Index] == Vehicle then
            table.remove(List, Index)
        end
    end
end

---@param Vehicle Element
function _MTAX:Unload(Vehicle)
    self:Forget(Vehicle)

    if isElement(Vehicle) then
        destroyElement(Vehicle)
    end
end

---@param Player Element
function _MTAX:Clear(Player)
    local List = self.Owned[Player] or {}

    for Index = #List, 1, -1 do
        self:Unload(List[Index])
    end

    self.Owned[Player] = nil
    self.SavedGravity[Player] = nil
end

--- Gravity

---@param Player Element
function _MTAX:RestoreGravity(Player)
    local Saved = self.SavedGravity[Player]
    if not Saved or not isElement(Player) then
        return
    end

    self.SavedGravity[Player] = nil
    setPedGravity(Player, Saved)
    Client.gravity(false, Player, Saved)
end

--- Events

---@param Vehicle Element
---@param Player Element
function _MTAX:Enter(Vehicle, Player)
    if not self.Data[Vehicle] then
        return
    end

    local Model = getElementModel(Vehicle)

    if Config.Vehicles.Armed[Model] and not Options:Get("weapons.vehiclesenabled") then
        toggleControl(Player, "vehicle_fire", false)
        toggleControl(Player, "vehicle_secondary_fire", false)
    end

    local Gravity = getPedGravity(Player)
    if Config.Vehicles.NormalGravity[Model] and math.abs(Gravity - NORMAL_GRAVITY) > 0.0001 then
        self.SavedGravity[Player] = Gravity
        setPedGravity(Player, NORMAL_GRAVITY)
        Client.gravity(false, Player, NORMAL_GRAVITY)
    end
end

---@param Vehicle Element
---@param Player Element
function _MTAX:Exit(Vehicle, Player)
    if not self.Data[Vehicle] then
        return
    end

    if Config.Vehicles.Armed[getElementModel(Vehicle)] then
        toggleControl(Player, "vehicle_fire", true)
        toggleControl(Player, "vehicle_secondary_fire", true)
    end

    self:RestoreGravity(Player)
end

---@param Vehicle Element
function _MTAX:Explode(Vehicle)
    local Data = self.Data[Vehicle]
    if not Data then
        return
    end

    if not isTimer(Data.Timer) then
        Data.Timer = setTimer(function()
            Data.Timer = nil
            self:Unload(Vehicle)
        end, Config.Vehicles.DestroyAfterExplode, 1)
    end

    local Driver = getVehicleController(Vehicle)
    if Driver then
        self:RestoreGravity(Driver)
    end
end

Vehicles = _MTAX:New()

Vehicles:Init()
