
local CAMERA_HEIGHT_OFFSET = 400
local CAMERA_DISTANCE_OFFSET = 60
local FLIGHT_DURATION = 10000

Client.smoothCamera = function ( x, y, z, rot )
    x = x or config.spawnPlayer.pos[ 1 ]
    y = y or config.spawnPlayer.pos[ 2 ]
    z = z or config.spawnPlayer.pos[ 3 ]
    rot = rot or config.spawnPlayer.rot or 0

    local rad = math.rad( rot )
    local offsetX = math.sin( rad ) * CAMERA_DISTANCE_OFFSET
    local offsetY = -math.cos( rad ) * CAMERA_DISTANCE_OFFSET

    local startX, startY, startZ = x + offsetX, y + offsetY, z + CAMERA_HEIGHT_OFFSET
    local endX, endY, endZ = x + offsetX * 0.2, y + offsetY * 0.2, z + 1.5

    local startTick = getTickCount( )
    setCameraMatrix( startX, startY, startZ, x, y, z )
    
    animate = function( )
        local progress = math.min( ( getTickCount( ) - startTick ) / FLIGHT_DURATION, 1 )
        local eased = 1 - ( 1 - progress ) ^ 3
        
        local camX = startX + ( endX - startX ) * eased
        local camY = startY + ( endY - startY ) * eased
        local camZ = startZ + ( endZ - startZ ) * eased

        setCameraMatrix( camX, camY, camZ, x, y, z )

        if progress >= 1 then
            removeEventHandler( 'onClientRender', root, animate )
            setCameraTarget( localPlayer )
        end
    end

    addEventHandler( 'onClientRender', root, animate )
end