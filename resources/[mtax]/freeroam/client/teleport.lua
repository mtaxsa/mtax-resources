---@alias Element userdata

local LAND_POLL = 50
local LOAD_GRAVITY = 0.001
local CAMERA_DELAY = 1000
local SETTLE_DELAY = 100
local INTERIOR_DELAY = 400

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Timer = nil
    self.CameraTimer = nil
    self.Deadline = nil
    self.SavedGravity = nil
    self.Pending = nil
    self.FadeHeld = false
    self.KnifeUntil = 0

    self.HoldHandler = function() fadeCamera(false, 0) end

    --- Add Events
    addEventHandler("onClientPlayerSpawn", localPlayer, function() self:Spawned() end)
    addEventHandler("onClientResourceStop", resourceRoot, function() self:Stop() end)
end

---@return boolean
function _MTAX:KnifeLocked()
    return getTickCount() < self.KnifeUntil
end

function _MTAX:Cancel()
    if isTimer(self.Timer) then
        killTimer(self.Timer)
    end

    if isTimer(self.CameraTimer) then
        killTimer(self.CameraTimer)
    end

    self.Timer = nil
    self.CameraTimer = nil
    self.Deadline = nil
end

function _MTAX:RestoreGravity()
    if self.SavedGravity then
        setGravity(self.SavedGravity)
        self.SavedGravity = nil
    end
end

--- Fade held while dead, until the respawn lands on the chosen spot

function _MTAX:HoldFade()
    if self.FadeHeld then
        return
    end

    self.FadeHeld = true
    fadeCamera(false, 0)
    addEventHandler("onClientPreRender", root, self.HoldHandler)
end

function _MTAX:ReleaseFade()
    if not self.FadeHeld then
        return
    end

    self.FadeHeld = false
    removeEventHandler("onClientPreRender", root, self.HoldHandler)
    fadeCamera(true)
end

--- Landing

---@param Vehicle Element
function _MTAX:Settle(Vehicle)
    if not isElement(Vehicle) then
        return
    end

    local _, _, Rotation = getElementRotation(Vehicle)
    setElementVelocity(Vehicle, 0, 0, 0)
    setElementAngularVelocity(Vehicle, 0, 0, 0)
    setElementRotation(Vehicle, 0, 0, Rotation)

    if not getPedOccupiedVehicle(localPlayer) then
        Server.reenter(false, Vehicle)
    end
end

-- Interiors float in the sky, so only the outside world snaps to the ground under the target.
---@param Element Element
---@param X number
---@param Y number
---@param Z number
---@param Offset number
---@param Snap boolean
---@return boolean
function _MTAX:Land(Element, X, Y, Z, Offset, Snap)
    if not isElement(Element) then
        self:Cancel()
        return true
    end

    local Final = Z + Offset

    if Snap then
        local Hit, _, _, Ground = processLineOfSight(X, Y, 3000, X, Y, -3000)
        local Expired = self.Deadline ~= nil and getTickCount() > self.Deadline

        if not Hit and not Expired then
            return false
        end

        if Hit then
            local Water = getWaterLevel(X, Y, 100)
            Final = (Water and math.max(Ground, Water) or Ground) + Offset
        else
            Main:Notify("notify.destination_timeout", nil, "warning")
        end
    end

    Server.moveTo(false, X, Y, Final)
    setCameraTarget(localPlayer)
    self:RestoreGravity()

    if getElementType(Element) == "vehicle" then
        Server.fade(false, true)
        setTimer(function() self:Settle(Element) end, SETTLE_DELAY, 1)
    else
        fadeCamera(true)
    end

    self:Cancel()
    return true
end

---@param X any
---@param Y any
---@param Z any
---@param Interior? number
---@param Dimension? number
---@return boolean
function _MTAX:To(X, Y, Z, Interior, Dimension)
    X, Y, Z = tonumber(X), tonumber(Y), tonumber(Z)
    if not X or not Y or not Z then
        return Main:Notify("error.invalid_coordinates")
    end

    local Vehicle = getPedOccupiedVehicle(localPlayer)
    if Vehicle and getVehicleController(Vehicle) ~= localPlayer then
        return Main:Notify("error.driver_teleport_only")
    end

    Interior = tonumber(Interior) or 0
    Dimension = tonumber(Dimension) or getElementDimension(localPlayer)

    if isPedDead(localPlayer) then
        self.Pending = { X = X, Y = Y, Z = Z, Interior = Interior, Dimension = Dimension }
        self:HoldFade()
        Main:Notify("notify.respawn_selected", nil, "info")
        return true
    end

    if Interior ~= getElementInterior(localPlayer) or Dimension ~= getElementDimension(localPlayer) then
        Server.world(false, Interior, Dimension)
        setCameraInterior(Interior)
    end

    if Main:Option("weapons.kniferestrictions") then
        self.KnifeUntil = getTickCount() + Config.Teleport.KnifeLock
    end

    self:Cancel()

    local Element = Vehicle or localPlayer
    local Offset = getElementDistanceFromCentreOfMassToBaseOfModel(Element) or 1
    local Snap = Interior == 0

    local Done = {
        x = string.format("%.0f", X),
        y = string.format("%.0f", Y),
        z = string.format("%.0f", Z),
    }

    if self:Land(Element, X, Y, Z, Offset, Snap) then
        Main:Notify("notify.teleported", Done, "success")
        return true
    end

    -- The ground under the target is not streamed yet: hover there until it loads.
    if Vehicle then
        Server.fade(false, false)
    else
        fadeCamera(false)
    end

    self.CameraTimer = setTimer(setCameraMatrix, CAMERA_DELAY, 1, X, Y, Z)

    if not self.SavedGravity then
        self.SavedGravity = getGravity()
        setGravity(LOAD_GRAVITY)
    end

    self.Deadline = getTickCount() + Config.Teleport.Timeout
    self.Timer = setTimer(function() self:Land(Element, X, Y, Z, Offset, Snap) end, LAND_POLL, 0)

    Main:Notify("notify.loading_destination", nil, "info")
    return true
end

---@param World any
---@param X any
---@param Y any
---@param Z any
---@return boolean
function _MTAX:Interior(World, X, Y, Z)
    World, X, Y, Z = tonumber(World), tonumber(X), tonumber(Y), tonumber(Z)
    if not World or not X or not Y or not Z then
        return false
    end

    local Vehicle = getPedOccupiedVehicle(localPlayer)
    if Vehicle and getVehicleController(Vehicle) ~= localPlayer then
        return Main:Notify("error.driver_interior_only")
    end

    self:Cancel()
    fadeCamera(false, 0.3)
    Server.world(false, World)
    setCameraInterior(World)

    setTimer(function()
        local Element = getPedOccupiedVehicle(localPlayer) or localPlayer
        local Offset = getElementDistanceFromCentreOfMassToBaseOfModel(Element) or 0.9

        Server.moveTo(false, X, Y, Z + Offset)
        setCameraTarget(localPlayer)
        fadeCamera(true, 0.5)
    end, INTERIOR_DELAY, 1)

    return true
end

--- Events

function _MTAX:Spawned()
    local Target = self.Pending
    if not Target then
        return
    end

    self.Pending = nil
    self:To(Target.X, Target.Y, Target.Z, Target.Interior, Target.Dimension)
    setTimer(function() self:ReleaseFade() end, 100, 1)
end

function _MTAX:Stop()
    self:Cancel()
    self:RestoreGravity()
    self.Pending = nil
    self:ReleaseFade()
    fadeCamera(true)
end

Teleport = _MTAX:New()

Teleport:Init()
