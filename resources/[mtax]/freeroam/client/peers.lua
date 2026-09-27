---@alias Element userdata

local LABEL_DISTANCE = 20
local LABEL_HEIGHT = 0.55
local LABEL_COLOR = { 245, 158, 11 }

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Flags = {}
    self.Drawing = false
    self.Label = "knife disabled"

    self.RenderHandler = function() self:Render() end

    --- Add Events
    addEventHandler("onClientPlayerQuit", root, function() local Source = source; self:Forget(Source) end)
    addEventHandler("onClientPlayerVehicleEnter", root, function(Vehicle, Seat) local Source = source; self:VehicleEnter(Source, Vehicle, Seat) end)
    addEventHandler("onClientElementStreamIn", root, function() local Source = source; self:StreamIn(Source) end)
    addEventHandler("onClientPlayerStealthKill", localPlayer, function(Target) self:StealthKill(Target) end)
end

---@param Player Element
---@param Key string
---@return boolean
function _MTAX:Get(Player, Key)
    local Set = self.Flags[Player]
    return Set ~= nil and Set[Key] == true
end

---@param List table[]
function _MTAX:Load(List)
    self.Flags = {}

    for _, Entry in ipairs(type(List) == "table" and List or {}) do
        if isElement(Entry.player) then
            self.Flags[Entry.player] = {
                warping   = Entry.warping == true,
                knifing   = Entry.knifing == true,
                ghostmode = Entry.ghostmode == true,
            }
        end
    end

    for _, Vehicle in ipairs(getElementsByType("vehicle", root, true)) do
        self:StreamIn(Vehicle)
    end

    self:SyncLabels()
end

---@param Player Element
---@param Key string
---@param Value boolean
function _MTAX:Set(Player, Key, Value)
    if not isElement(Player) then
        return
    end

    self.Flags[Player] = self.Flags[Player] or {}
    self.Flags[Player][Key] = Value == true

    if Key == "knifing" then
        self:SyncLabels()
    elseif Key == "ghostmode" then
        local Vehicle = getPedOccupiedVehicle(Player)
        if Vehicle and getVehicleController(Vehicle) == Player then
            self:ApplyGhost(Vehicle, Value == true)
        end
    end
end

---@param Player Element
function _MTAX:Forget(Player)
    if self.Flags[Player] then
        self.Flags[Player] = nil
        self:SyncLabels()
    end
end

--- Ghost mode

-- A pair of cars ignores each other when either driver is a ghost.
---@param Vehicle Element
---@param Ghost boolean
function _MTAX:ApplyGhost(Vehicle, Ghost)
    if not isElement(Vehicle) then
        return
    end

    for _, Other in ipairs(getElementsByType("vehicle", root, true)) do
        if Other ~= Vehicle then
            local Driver = getVehicleController(Other)
            local Pair = Ghost or (Driver and self:Get(Driver, "ghostmode")) or false
            setElementCollidableWith(Vehicle, Other, not Pair)
        end
    end
end

---@param Player Element
---@param Vehicle Element
---@param Seat number
function _MTAX:VehicleEnter(Player, Vehicle, Seat)
    if Seat == 0 then
        self:ApplyGhost(Vehicle, self:Get(Player, "ghostmode"))
    end
end

---@param Element Element
function _MTAX:StreamIn(Element)
    if getElementType(Element) ~= "vehicle" then
        return
    end

    local Driver = getVehicleController(Element)
    self:ApplyGhost(Element, Driver and self:Get(Driver, "ghostmode") or false)
end

--- Knife

---@param Target Element
function _MTAX:StealthKill(Target)
    if Teleport:KnifeLocked() then
        cancelEvent()
        Main:Notify("notify.knife_after_teleport", nil, "warning")
        return
    end

    if self:Get(localPlayer, "knifing") or self:Get(Target, "knifing") then
        cancelEvent()
        Main:Notify("notify.stealth_kill_blocked", nil, "warning")
    end
end

---@param Text string
function _MTAX:SetLabel(Text)
    if type(Text) == "string" and Text ~= "" then
        self.Label = Text
    end
end

function _MTAX:SyncLabels()
    local Wanted = false

    for Player, Set in pairs(self.Flags) do
        if Set.knifing and isElement(Player) then
            Wanted = true
            break
        end
    end

    if Wanted and not self.Drawing then
        self.Drawing = true
        addEventHandler("onClientRender", root, self.RenderHandler)
    elseif not Wanted and self.Drawing then
        self.Drawing = false
        removeEventHandler("onClientRender", root, self.RenderHandler)
    end
end

function _MTAX:Render()
    for Player, Set in pairs(self.Flags) do
        if Set.knifing and isElement(Player) and isElementStreamedIn(Player) then
            local X, Y, Z = getPedBonePosition(Player, 6)

            if X then
                local ScreenX, ScreenY, Distance = getScreenFromWorldPosition(X, Y, Z + LABEL_HEIGHT)

                if ScreenX and Distance and Distance < LABEL_DISTANCE then
                    local Alpha = math.floor(math.max(0, math.min(1, (LABEL_DISTANCE - Distance) / 6)) * 255)

                    dxDrawText(self.Label, ScreenX - 80, ScreenY - 9, ScreenX + 80, ScreenY + 9,
                        tocolor(LABEL_COLOR[1], LABEL_COLOR[2], LABEL_COLOR[3], Alpha),
                        1, "default-bold", "center", "center")
                end
            end
        end
    end
end

Peers = _MTAX:New()

Peers:Init()
