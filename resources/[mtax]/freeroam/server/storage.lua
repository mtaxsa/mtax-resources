local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

---@param Path string
---@return table|nil
function _MTAX:Read(Path)
    if not fileExists(Path) then
        return nil
    end

    local File = fileOpen(Path, true)
    if not File then
        return nil
    end

    local Size = fileGetSize(File) or 0
    local Text = Size > 0 and fileRead(File, Size) or ""
    fileClose(File)

    if Text == "" then
        return nil
    end

    local Ok, Value = pcall(fromJSON, Text)
    return Ok and type(Value) == "table" and Value or nil
end

---@param Path string
---@param Value table
---@return boolean
function _MTAX:Write(Path, Value)
    local File = fileCreate(Path)
    if not File then
        return false
    end

    fileWrite(File, toJSON(Value))
    fileClose(File)
    return true
end

Storage = _MTAX:New()
