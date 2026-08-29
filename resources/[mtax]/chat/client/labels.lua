---@alias Element userdata

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.List = {}
    self.NextId = 0
    self.LastKey = nil
    self.Running = false

    self.RenderHandler = function() self:Render() end

    addEventHandler("onClientResourceStop", resourceRoot, function() self:Stop() end)
end

---@param Value number
---@param Low number
---@param High number
---@return number
function _MTAX:Clamp(Value, Low, High)
    if Value < Low then
        return Low
    end

    if Value > High then
        return High
    end

    return Value
end

---@param Anchor Element
function _MTAX:Trim(Anchor)
    local Mine = {}

    for _, Label in ipairs(self.List) do
        if Label.Anchor == Anchor then
            Mine[#Mine + 1] = Label
        end
    end

    while #Mine >= Config.ThreeD.Stack do
        local Oldest = table.remove(Mine, 1)

        for Index, Label in ipairs(self.List) do
            if Label == Oldest then
                table.remove(self.List, Index)
                break
            end
        end
    end
end

---@param Anchor Element
---@param Message table
function _MTAX:Push(Anchor, Message)
    if not Config.ThreeD.Enabled or not isElement(Anchor) then
        return
    end

    self:Trim(Anchor)

    self.NextId = self.NextId + 1
    self.List[#self.List + 1] = {
        Id      = self.NextId,
        Anchor  = Anchor,
        Kind    = Message.kind,
        Name    = Message.name,
        Text    = Message.text,
        Sticker = Message.sticker,
        Expires = getTickCount() + Config.ThreeD.Duration,
    }

    self:Start()
end

function _MTAX:Clear()
    self.List = {}
    self.LastKey = nil
    self:Stop()
    sendNuiMessage({ action = "labels", data = {} })
end

function _MTAX:Expire()
    local Now = getTickCount()

    for Index = #self.List, 1, -1 do
        local Label = self.List[Index]
        if Now >= Label.Expires or not isElement(Label.Anchor) then
            table.remove(self.List, Index)
        end
    end
end

function _MTAX:Render()
    self:Expire()

    if #self.List == 0 then
        self:Stop()
        self.LastKey = nil
        sendNuiMessage({ action = "labels", data = {} })
        return
    end

    if not isElement(localPlayer) then
        return
    end

    local Now = getTickCount()
    local OX, OY, OZ = getElementPosition(localPlayer)
    local Payload = {}
    local Slots = {}
    local Key = ""

    for Index = #self.List, 1, -1 do
        local Label = self.List[Index]
        local X, Y, Z = getElementPosition(Label.Anchor)
        local Distance = getDistanceBetweenPoints3D(OX, OY, OZ, X, Y, Z)

        if Distance <= Config.ThreeD.Distance then
            local ScreenX, ScreenY = getScreenFromWorldPosition(X, Y, Z + Config.ThreeD.Height)

            if ScreenX then
                local Slot = Slots[Label.Anchor] or 0
                Slots[Label.Anchor] = Slot + 1

                local Row = {
                    i = Label.Id,
                    k = Label.Kind,
                    n = Label.Name,
                    t = Label.Text,
                    s = Label.Sticker,
                    x = math.floor(ScreenX),
                    y = math.floor(ScreenY),
                    o = Slot,
                    a = self:Clamp((Label.Expires - Now) / 500, 0, 1),
                    z = self:Clamp(1 - (Distance / Config.ThreeD.Distance) * 0.45, 0.55, 1),
                }

                table.insert(Payload, 1, Row)
                Key = Key .. Row.i .. ":" .. Row.x .. ":" .. Row.y .. ":" ..
                      math.floor(Row.a * 20) .. ":" .. math.floor(Row.z * 40) .. ";"
            end
        end
    end

    if Key == self.LastKey then
        return
    end

    self.LastKey = Key
    sendNuiMessage({ action = "labels", data = Payload })
end

function _MTAX:Start()
    if self.Running then
        return
    end

    self.Running = true
    addEventHandler("onClientRender", root, self.RenderHandler)
end

function _MTAX:Stop()
    if not self.Running then
        return
    end

    self.Running = false
    removeEventHandler("onClientRender", root, self.RenderHandler)
end

Labels = _MTAX:New()

Labels:Init()
