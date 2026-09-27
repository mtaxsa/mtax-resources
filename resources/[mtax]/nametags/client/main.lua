---@alias Element userdata

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.ScreenW, self.ScreenH = guiGetScreenSize()

    --- Add Events
    addEventHandler("onClientRender", root, function() self:Render() end)
end

--- Aim

-- A player or vehicle the local player aims at with a handgun..rifle slot is always tagged at full alpha.
---@return Element|false, Element|false
function _MTAX:AimTargets()
    local Slot = getPedWeaponSlot(localPlayer)
    if not Slot or Slot < 2 or Slot > 6 then
        return false, false
    end

    local SX, SY, SZ = getPedTargetStart(localPlayer)
    local EX, EY, EZ = getPedTargetEnd(localPlayer)
    if not SX or not EX or (SX == EX and SY == EY and SZ == EZ) then
        return false, false
    end

    local Hit, _, _, _, HitElement = processLineOfSight(SX, SY, SZ, EX, EY, EZ,
        true, true, true, true, true, true, false, true, localPlayer)

    if not Hit or not isElement(HitElement) then
        return false, false
    end

    local Type = getElementType(HitElement)
    if Type == "player" then
        return HitElement, false
    end

    if Type == "vehicle" then
        return false, HitElement
    end

    return false, false
end

--- Visibility

---@param Player Element
---@param Camera number[]
---@param LocalVehicle Element|false
---@param AimPlayer Element|false
---@param AimVehicle Element|false
---@return number|false
function _MTAX:Distance(Player, Camera, LocalVehicle, AimPlayer, AimVehicle)
    local X, Y, Z = getElementPosition(Player)
    local Distance = getDistanceBetweenPoints3D(Camera[1], Camera[2], Camera[3], X, Y, Z)
    local Vehicle = getPedOccupiedVehicle(Player)

    local Forced = Player == AimPlayer
        or (AimVehicle and AimVehicle == Vehicle)
        or (LocalVehicle and LocalVehicle == Vehicle)

    if not Forced and (Distance >= Config.ViewRange or not isElementOnScreen(Player)) then
        return false
    end

    local Hit, _, _, _, HitElement = processLineOfSight(Camera[1], Camera[2], Camera[3], X, Y, Z,
        true, true, false, true, true, false, false, false, LocalVehicle or nil)

    if Hit and not (Vehicle and HitElement == Vehicle) then
        return false
    end

    return Distance
end

---@param Tag table
---@param AimPlayer Element|false
---@param AimVehicle Element|false
---@return number
function _MTAX:Alpha(Tag, AimPlayer, AimVehicle)
    if Tag.Distance < Config.FullAlphaDistance or Tag.Player == AimPlayer then
        return Config.MaxAlpha
    end

    if AimVehicle and AimVehicle == getPedOccupiedVehicle(Tag.Player) then
        return Config.MaxAlpha
    end

    local Fade = 1 - ((Tag.Distance - Config.FullAlphaDistance) / (Config.ViewRange - Config.FullAlphaDistance))
    return math.floor(Config.MaxAlpha * Fade)
end

--- Health

-- MTA CClientPed::GetMaxHealth: the MAX_HEALTH stat * 0.176, at least 1. Result scaled to 0..512.
---@param Player Element
---@return number
function _MTAX:Health(Player)
    local Stat = getPedStat(Player, Config.MaxHealthStat) or Config.DefaultMaxHealthStat
    local MaxHealth = math.max(Stat * 0.176, 1)
    local Percent = math.min((getElementHealth(Player) or 0) / MaxHealth * 100, 100)

    return Percent * 7.52 / (750 / 510)
end

---@param Health number
---@return number, number
function _MTAX:HealthColor(Health)
    if Health > 255 then
        return math.min(math.floor(512 - Health), 255), 255
    end

    return 255, math.floor(Health)
end

--- Draw

---@param Left number
---@param Top number
---@param Right number
---@param Bottom number
---@param Color number
function _MTAX:Rect(Left, Top, Right, Bottom, Color)
    dxDrawRectangle(Left, Top, Right - Left, Bottom - Top, Color, false, true)
end

---@param Player Element
---@param Alpha number
function _MTAX:Draw(Player, Alpha)
    if not isPlayerNametagShowing(Player) then
        return
    end

    local Health = self:Health(Player)
    if Health <= 0 then
        return
    end

    local HX, HY, HZ = getPedBonePosition(Player, Config.HeadBone)
    if not HX then
        return
    end

    local ScreenX, ScreenY = getScreenFromWorldPosition(HX, HY, HZ + Config.HeadOffset, 50, false)
    if not ScreenX then
        return
    end

    local BarWidth = self.ScreenW * Config.Bar.Width
    local BarHeight = self.ScreenH * Config.Bar.Height
    local Border = self.ScreenW * Config.Bar.Border

    local Left = ScreenX - BarWidth * 0.5
    local Right = ScreenX + BarWidth * 0.5
    local Bottom = ScreenY
    local Top = Bottom - BarHeight

    local Text = getPlayerNametagText(Player) or ""
    local R, G, B = getPlayerNametagColor(Player)
    local TextBottom = math.floor(Top - Border - Config.TextGap)
    local TextX = math.floor(ScreenX)

    dxDrawText(Text, TextX + 1, TextBottom + 1, TextX + 1, TextBottom + 1,
        tocolor(Config.ShadowColor[1], Config.ShadowColor[2], Config.ShadowColor[3], 255),
        Config.Scale, Config.Font, "center", "bottom", false, false, false, false, true)
    dxDrawText(Text, TextX, TextBottom, TextX, TextBottom, tocolor(R or 255, G or 255, B or 255, 255),
        Config.Scale, Config.Font, "center", "bottom", false, false, false, false, true)

    local Red, Green = self:HealthColor(Health)
    local Removed = BarWidth - (Health / 512 * BarWidth)
    local Armor = getPedArmor(Player) or 0

    self:Rect(Left - Border, Top - Border, Right + Border, Bottom + Border, tocolor(0, 0, 0, Alpha))

    if Armor > 0 then
        local ArmorColor = tocolor(Config.ArmorColor[1], Config.ArmorColor[2], Config.ArmorColor[3],
            math.floor(255 * (Armor / 100) * (Alpha / 255)))

        self:Rect(Left - Border, Top - Border, Left, Bottom + Border, ArmorColor)
        self:Rect(Right, Top - Border, Right + Border, Bottom + Border, ArmorColor)
        self:Rect(Left, Top - Border, Right, Top, ArmorColor)
        self:Rect(Left, Bottom, Right, Bottom + Border, ArmorColor)
    end

    self:Rect(Left, Top, Right - Removed, Bottom, tocolor(Red, Green, 0, Alpha))
    self:Rect(Right - Removed, Top, Right, Bottom,
        tocolor(math.floor(Red * 0.33), math.floor(Green * 0.33), 0, Alpha))
end

--- Render

function _MTAX:Render()
    local Players = getElementsByType("player", root, true)
    if #Players <= 1 then
        return
    end

    local CX, CY, CZ = getCameraMatrix()
    if not CX then
        return
    end

    local Camera = { CX, CY, CZ }
    local Dimension = getElementDimension(localPlayer)
    local Interior = getElementInterior(localPlayer)
    local LocalVehicle = getPedOccupiedVehicle(localPlayer)
    local AimPlayer, AimVehicle = self:AimTargets()
    local Tags = {}

    for _, Player in ipairs(Players) do
        if Player ~= localPlayer
            and getElementDimension(Player) == Dimension
            and getElementInterior(Player) == Interior then
            local Distance = self:Distance(Player, Camera, LocalVehicle, AimPlayer, AimVehicle)

            if Distance then
                Tags[#Tags + 1] = { Player = Player, Distance = Distance }
            end
        end
    end

    -- Farthest first, so the closest tag ends on top.
    table.sort(Tags, function(A, B) return A.Distance > B.Distance end)

    for _, Tag in ipairs(Tags) do
        self:Draw(Tag.Player, self:Alpha(Tag, AimPlayer, AimVehicle))
    end
end

local Main = _MTAX:New()

Main:Init()
