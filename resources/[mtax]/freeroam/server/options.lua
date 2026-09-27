local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.Overrides = Storage:Read(Config.SettingsFile) or {}
end

---@param Value any
---@return any
function _MTAX:Copy(Value)
    if type(Value) ~= "table" then
        return Value
    end

    local Result = {}
    for Key, Item in pairs(Value) do
        Result[Key] = self:Copy(Item)
    end

    return Result
end

-- Accepts both "gamespeed.max" and the legacy "gamespeed/max".
---@param Key any
---@return string
function _MTAX:Normalize(Key)
    return (tostring(Key or ""):gsub("/", "."))
end

---@param Key string
---@return any
function _MTAX:Default(Key)
    local Node = Config.Options

    for Part in self:Normalize(Key):gmatch("[^%.]+") do
        if type(Node) ~= "table" then
            return nil
        end

        Node = Node[Part]
    end

    return Node
end

---@param Key string
---@return any
function _MTAX:Get(Key)
    local Stored = self.Overrides[self:Normalize(Key)]
    if Stored ~= nil then
        return Stored
    end

    return self:Default(Key)
end

---@param Key string
---@param Value string|nil
---@return boolean
function _MTAX:Set(Key, Value)
    Key = self:Normalize(Key)

    if Value == "true" then
        Value = true
    elseif Value == "false" then
        Value = false
    elseif type(Value) == "string" then
        Value = tonumber(Value) or Value
    end

    if Value == nil or Value == self:Default(Key) then
        Value = nil
    end

    if self.Overrides[Key] == Value then
        return true
    end

    self.Overrides[Key] = Value
    return Storage:Write(Config.SettingsFile, self.Overrides)
end

--- Defaults merged with every override, as sent to clients.
---@return table
function _MTAX:Resolved()
    local Result = self:Copy(Config.Options)

    for Key, Value in pairs(self.Overrides) do
        local Node = Result
        local Parts = {}

        for Part in Key:gmatch("[^%.]+") do
            Parts[#Parts + 1] = Part
        end

        for Index = 1, #Parts - 1 do
            if type(Node[Parts[Index]]) ~= "table" then
                Node[Parts[Index]] = {}
            end
            Node = Node[Parts[Index]]
        end

        Node[Parts[#Parts]] = Value
    end

    return Result
end

---@param List any
---@param Value any
---@return boolean
function _MTAX:Contains(List, Value)
    if type(List) ~= "table" then
        return false
    end

    for _, Item in pairs(List) do
        if Item == Value then
            return true
        end
    end

    return false
end

Options = _MTAX:New()

Options:Init()
