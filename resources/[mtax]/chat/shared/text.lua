---@alias ColorRun { text: string, color: string }

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

---@param Value any
---@return string
function _MTAX:Line(Value)
    if type(Value) ~= "string" then
        return ""
    end

    local Text = Value:gsub("[\0-\31\127]", " ")
    Text = Text:gsub("  +", " ")
    Text = Text:gsub("^%s+", "")
    Text = Text:gsub("%s+$", "")
    return Text
end

---@param Text string
---@return number
function _MTAX:Length(Text)
    if utfLen then
        return utfLen(Text) or #Text
    end

    return #Text
end

---@param Text string
---@param Limit number
---@return string
function _MTAX:Cut(Text, Limit)
    if utfSub then
        return utfSub(Text, 1, Limit) or Text
    end

    return Text:sub(1, Limit)
end

---@param Text string
---@param Fallback string
---@return string, ColorRun[]
function _MTAX:ColorCoded(Text, Fallback)
    local Segments = {}
    local Color = Fallback
    local Cursor = 1

    while Cursor <= #Text do
        local Start, Stop, Hex = Text:find("#(%x%x%x%x%x%x)", Cursor)
        if not Start then
            break
        end

        if Start > Cursor then
            Segments[#Segments + 1] = { text = Text:sub(Cursor, Start - 1), color = Color }
        end

        Color = "#" .. Hex
        Cursor = Stop + 1
    end

    if Cursor <= #Text then
        Segments[#Segments + 1] = { text = Text:sub(Cursor), color = Color }
    end

    return (Text:gsub("#%x%x%x%x%x%x", "")), Segments
end

---@param R? number
---@param G? number
---@param B? number
---@return string
function _MTAX:Rgb(R, G, B)
    return string.format("#%02X%02X%02X",
        math.floor(tonumber(R) or 231) % 256,
        math.floor(tonumber(G) or 217) % 256,
        math.floor(tonumber(B) or 176) % 256)
end

---@return string
function _MTAX:Timestamp()
    local Now = getRealTime()
    if type(Now) ~= "table" then
        return ""
    end

    return string.format("%02d:%02d", Now.hour or 0, Now.minute or 0)
end

ChatText = _MTAX:New()
