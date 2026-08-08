screenWidth, screenHeight = guiGetScreenSize( )

local fonts = { }

scale = 1

if ( screenHeight <= 480 ) then
     scale = 0.7
elseif ( screenHeight <= 576 ) then
     scale = 0.8
elseif ( screenHeight <= 600 ) then
     scale = 0.9
elseif ( screenHeight <= 720 ) or ( screenHeight <= 768 ) then
     scale = 1
elseif ( screenHeight <= 900 ) then
     scale = 1.1
elseif ( screenHeight <= 1050 ) then
     scale = 1.15
elseif ( screenHeight <= 1080 ) then
     scale = 1
else
     scale = math.min (math.max (0.75, (screenHeight / 768)), 1.2)
end

parentWidth, parentHeight = ( 1165 * scale ), ( 33 * scale )


getFont = function(font, size)
     if (not fonts[font]) then
          fonts[font] = { }
     end
     if (not fonts[font][size]) then
          fonts[font][size] = dxCreateFont('fonts/'..font, (size * scale) * (72 / 96), false, 'cleartype') or 'default-bold'
     end
     return fonts[font][size]
end

_dxDrawText = dxDrawText
function dxDrawText(text, x, y, w, h, ...)
    local x, y, w, h = x * scale, y * scale, w * scale, h * scale
    return _dxDrawText(text, x, y, x + w, y + h, ...)
end


_dxDrawRectangle = dxDrawRectangle
function dxDrawRectangle( x, y, w, h, ...)
    local x, y, w, h = x * scale, y * scale, w * scale, h * scale
    return _dxDrawRectangle(x, y, w, h, ...)
end

_dxDrawImage = dxDrawImage
function dxDrawImage( x, y, w, h, path, ...)
    local x, y, w, h = x * scale, y * scale, w * scale, h * scale
    return _dxDrawImage(x, y, w, h, path, ...)
end



local fps = 0
local frames = 0
local lastSecond = getTickCount()
local stats = getSystemStats( )
local visible = false

renderFpsPing = function( )

    local pl = getNetworkStats( )
    local packetLoss = pl and pl.packetlossLastSecond or 0

    frames = frames + 1
    local now = getTickCount()
    if now - lastSecond >= 1000 then
        fps = frames
        frames = 0
        lastSecond = now
    end

    local ping = 0
    if localPlayer then
        local value = getPlayerPing( localPlayer )
        if value then ping = value end
    end

    dxDrawRectangle( 0, 0, 1165, 33, tocolor( 19, 21, 24, 150 ) )
    dxDrawRectangle( 0, 0, 1165, 1, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 0, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 159, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 0, 32, 1165, 1, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 1164, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 319, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 479, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 639, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 800, 0, 1, 33, tocolor( 81, 179, 236 ) )
    dxDrawRectangle( 959, 0, 1, 33, tocolor( 81, 179, 236 ) )

    dxDrawText( 'FPS: '..fps, 14, 7, 62, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'Ping: '..ping, 182, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'PL: '..string.format( '%.1f%%', packetLoss ), 338, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'CPU: '..string.format( '%.1f%%', stats.cpu.usage ), 500, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'GPU: '..string.format( '%.1f%%', stats.gpu.usage ), 657, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'VRAM: '..string.format( '%.1f', stats.gpu.memoryUsed / 1024 )..'/'..string.format( '%.1f GB', stats.gpu.memoryTotal / 1024 ), 818, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )
    dxDrawText( 'RAM: '..string.format( '%.1f', stats.ram.used / 1073741824 )..'/'..string.format( '%.1f GB', stats.ram.total / 1073741824 ), 981, 7, 70, 18, tocolor( 255, 255, 255 ), 1.0, getFont( 'inter-regular.ttf', 14 ), 'left', 'center' )

end


setTimer( function( )
    stats = getSystemStats( )
end, 1000, 0 )


addCommandHandler( 'showstats', function( )
     visible = not visible
     if visible then
          addEventHandler( 'onClientRender', root, renderFpsPing )
     else
          removeEventHandler( 'onClientRender', root, renderFpsPing )
     end
end)