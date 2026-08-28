local Fonts = { }

local ScreenWidth, ScreenHeight = guiGetScreenSize()
local ScaleMap = {
    {Height = 480, Scale = 0.7},
    {Height = 576, Scale = 0.8},
    {Height = 600, Scale = 0.9},
    {Height = 768, Scale = 1},
    {Height = 900, Scale = 1.1},
    {Height = 1050, Scale = 1.15},
    {Height = 1080, Scale = 1}
}

function CalculateScale()
    for _, val in pairs(ScaleMap) do
        if ScreenHeight <= val.Height then
            return val.Scale
        end
    end

    return math.min(math.max(0.75, (ScreenHeight / 768)), 1.2)
end

local Scale = CalculateScale()

local ParentWidth, ParentHeight = (1165 * Scale), (33 * Scale)

---Get Font
---@param font size
GetFont = function(font, size)
    if not Fonts[font] then
        Fonts[font] = {}
    end

    if not Fonts[font][size] then
        Fonts[font][size] = dxCreateFont('fonts/'..font, (size * Scale) * (72 / 96), false, 'cleartype') or 'default-bold'
    end

    return Fonts[font][size]
end

_dxDrawText = dxDrawText
_dxDrawRectangle = dxDrawRectangle
_dxDrawImage = dxDrawImage

--- Draws text.
---@param text string The text. A `\n` starts a new line.
---@param left number
---@param top number
---@param right? number
---@param bottom? number
---@param color? number Text colour.
---@param scale? number Multiplies the font size.
---@param font? any The name of a [built-in font](#built-in-fonts), or an element returned by `dxCreateFont`.
---@param alignX? string `"left"`, `"center"` or `"right"`, within the box.
---@param alignY? string `"top"`, `"center"` or `"bottom"`, within the box.
---@param clip? boolean Accepted, but has no effect.
---@param wordBreak? boolean Accepted, but has no effect on drawing.
---@param postGUI? boolean Accepted, but has no effect.
---@param colorCoded? boolean Reads `#RRGGBB` codes inside the text.
---@return boolean # `true` if the text was drawn, `false` if the font is not valid.
function dxDrawText(text, x, y, w, h, ...)
    local x, y, w, h = x * Scale, y * Scale, w * Scale, h * Scale
    return _dxDrawText(text, x, y, x + w, y + h, ...)
end

--- Draws a filled rectangle.
---@param x number
---@param y number
---@param width number
---@param height number
---@param color? number Fill colour.
---@return boolean # `true` if the rectangle was drawn, `false` otherwise.
function dxDrawRectangle( x, y, w, h, ...)
    local x, y, w, h = x * Scale, y * Scale, w * Scale, h * Scale
    return _dxDrawRectangle(x, y, w, h, ...)
end

--- Draws an image on the screen.
---@param x number
---@param y number
---@param width number
---@param height number
---@param image material The path to an image file in your resource, or a texture, render target, screen source or shader element.
---@param rotation? number Rotation in degrees, clockwise.
---@param rotationCenterOffsetX? number
---@param rotationCenterOffsetY? number
---@param color? number Tints the image; the alpha channel controls transparency.
---@return boolean # `true` if the image was drawn, `false` if the size is not positive or the image could not be loaded.
function dxDrawImage( x, y, w, h, path, ...)
    local x, y, w, h = x * Scale, y * Scale, w * Scale, h * Scale
    return _dxDrawImage(x, y, w, h, path, ...)
end

local FPS = 0
local Frames = 0
local lastSecond = getTickCount()
local Ping = getPlayerPing(localPlayer)
local Stats = getSystemStats()
local PacketLoss = getNetworkStats().packetlossLastSecond
local Visible = false
local UpdateTimer = nil

RenderFpsPing = function()
    Frames = Frames + 1

    dxDrawRectangle(0, 0, 1165, 33, tocolor(19, 21, 24, 150))
    dxDrawRectangle(0, 0, 1165, 1, tocolor(81, 179, 236))
    dxDrawRectangle(0, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(159, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(0, 32, 1165, 1, tocolor(81, 179, 236))
    dxDrawRectangle(1164, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(319, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(479, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(639, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(800, 0, 1, 33, tocolor(81, 179, 236))
    dxDrawRectangle(959, 0, 1, 33, tocolor(81, 179, 236))

    local fontInterRegular = GetFont('inter-regular.ttf', 14)

    dxDrawText('FPS: '..FPS, 14, 7, 62, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')
    dxDrawText('Ping: '..Ping, 182, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')
    dxDrawText('PL: '..string.format('%.1f%%', PacketLoss), 338, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')
    dxDrawText('CPU: '..string.format('%.1f%%', Stats.cpu.usage), 500, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')

    dxDrawText('GPU: '..string.format('%.1f%%', Stats.gpu.usage), 657, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')
    dxDrawText('VRAM: '..string.format('%.1f', Stats.gpu.memoryUsed / 1024)..'/'..string.format('%.1f GB', Stats.gpu.memoryTotal / 1024), 818, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')

    dxDrawText('RAM: '..string.format('%.1f', Stats.ram.used / 1073741824)..'/'..string.format('%.1f GB', Stats.ram.total / 1073741824), 981, 7, 70, 18, tocolor(255, 255, 255), 1.0, fontInterRegular, 'left', 'center')
end

function UpdateData()
    if not Visible then
        return
    end

    FPS = Frames
    Frames = 0
    Stats = getSystemStats()
    Ping = getPlayerPing(localPlayer)
    PacketLoss = getNetworkStats().packetlossLastSecond
end

addCommandHandler('showstats', function()
    Visible = not Visible

    if Visible then
        UpdateData()
        addEventHandler('onClientRender', root, RenderFpsPing)
        UpdateTimer = setTimer(UpdateData, 1000, 0)
        return
    end

    if isTimer(UpdateTimer) then killTimer(UpdateTimer) end
    removeEventHandler('onClientRender', root, RenderFpsPing)
end)