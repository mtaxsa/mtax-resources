---@alias Element userdata

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

function _MTAX:Init()
    self.List = Storage:Read(Config.Bookmarks.File) or {}
end

---@param Player Element
---@return string
function _MTAX:Key(Player)
    local Ok, Serial = pcall(function() return exports["accounts"]:getPlayerSerial(Player) end)
    if Ok and type(Serial) == "string" and Serial ~= "" then
        return Serial
    end

    return "name:" .. (getPlayerName(Player) or ""):gsub("#%x%x%x%x%x%x", "")
end

---@param Player Element
---@return table[]
function _MTAX:Get(Player)
    return self.List[self:Key(Player)] or {}
end

---@param Player Element
---@param Name any
---@return table[]|false, string?, table?
function _MTAX:Add(Player, Name)
    local Key = self:Key(Player)
    local List = self.List[Key] or {}

    if #List >= Config.Bookmarks.Max then
        return false, "error.bookmark_limit", { max = Config.Bookmarks.Max }
    end

    Name = tostring(Name or ""):gsub("[\0-\31\127]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if Name == "" then
        Name = "#" .. (#List + 1)
    end

    local X, Y, Z = getElementPosition(Player)

    List[#List + 1] = {
        name      = Name:sub(1, Config.Bookmarks.NameLength),
        x         = X,
        y         = Y,
        z         = Z,
        interior  = getElementInterior(Player),
        dimension = getElementDimension(Player),
    }

    self.List[Key] = List
    Storage:Write(Config.Bookmarks.File, self.List)
    return List
end

---@param Player Element
---@param Index any
---@return table[]
function _MTAX:Delete(Player, Index)
    local Key = self:Key(Player)
    local List = self.List[Key]

    Index = tonumber(Index)
    if not List or not Index or not List[Index] then
        return self:Get(Player)
    end

    table.remove(List, Index)
    Storage:Write(Config.Bookmarks.File, self.List)
    return List
end

Bookmarks = _MTAX:New()

Bookmarks:Init()
