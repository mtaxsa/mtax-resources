

addCommandHandler( 'rot', function( )
    local x, y, z = getElementRotation( localPlayer )
    setClipboard( tostring( z ) )
    outputDebugString( 'Rotation successfully copied.', 3 )
end)


addCommandHandler( 'pos', function( )
    local x, y, z = getElementPosition( localPlayer )
    local position = table.concat( { x, y, z }, ', ' )
    setClipboard( position )
    outputDebugString( 'Position successfully copied.', 3 )
end)


addCommandHandler( 'matrix', function( )
     local x, y, z, lx, ly, lz = getCameraMatrix(  )
     local matrix = table.concat( { x, y, z, lx, ly, lz }, ', ' )
     setClipboard( matrix )
     outputDebugString( 'Camera matrix successfully copied.', 3 )
end)


addCommandHandler( 'bindkey', function( _, key, cmd )
     Server.saveBind( function( key, cmd )
          if key and cmd then
               bindKey( key, 'down', function( )
                    executeCommandHandler( cmd )
               end)
          end
     end, key, cmd )
end)


Client.executeBind = function( key, cmd )
     bindKey( key, 'down', function( )
          executeCommandHandler( cmd )
     end)
end


addCommandHandler( 'unbindkey', function( _, key )
    unbindKey( key, 'down' )
end)


addCommandHandler( 'fly', function( )
    Server.fly( fly )
end)


-- Fly


local tFly = false
local keyStates = {
    up = 'up',
    down = 'up',
    w = 'up',
    backward = 'up',
    left = 'up',
    right = 'up',
    slow = 'up',
    fast = 'up',
    maxSpeed = 'up'
}


fly = function( isAuthorized )
    if not isAuthorized then return end
    if not isTimer( tFly ) then
        tFly = setTimer( handleFlying, 0, 0 )
        bindKeys( )
        Server.alpha( false, 0 )
    else
        killTimer( tFly )
        unbindKeys( )
        resetKeyStates( )
        Server.alpha( false, 255 )
    end
end


function bindKeys( )
     local keysToBind = {
          {'lshift', 'fast'},
          {'rshift', 'fast'},
          {'lctrl', 'down'},
          {'rctrl', 'down'},
          {'w', 'w'},
          {'s', 's'},
          {'a', 'a'},
          {'d', 'd'},
          {'lalt', 'slow'},
          {'space', 'up'},
          {'ralt', 'slow'},
          {'mouse1', 'maxSpeed'}
     }
    for _, keyPair in ipairs(keysToBind) do
        bindKey(keyPair[1], 'both', updateKeyState, keyPair[2])
    end
end


function unbindKeys( )
     local keysToUnbind = {
          'lshift', 'rshift', 'lctrl', 'rctrl',
          'w', 's', 'a', 'd',
          'lalt', 'space', 'ralt', 'mouse1'
     }
     for _, key in ipairs(keysToUnbind) do
          unbindKey(key, 'both', updateKeyState)
     end
end


function updateKeyState(key, state, action)
    keyStates[action] = state
end


function resetKeyStates( )
    for key, _ in pairs(keyStates) do
        keyStates[key] = 'up'
    end
end


function getCameraDirection( )
     local x, y, z, lx, ly, lz = getCameraMatrix()
     local dx, dy, dz = lx - x, ly - y, lz - z
     local len = math.sqrt(dx^2 + dy^2 + dz^2)
     return dx / len, dy / len, dz / len
end


function handleFlying( )
     local x, y, z = getElementPosition(localPlayer)
     local dx, dy, dz = getCameraDirection()
     local speed = determineSpeed()
     local movement = computeMovement(dx, dy, dz, speed)
     x, y, z = x + movement.x, y + movement.y, z + movement.z
     setElementPosition(localPlayer, x, y, z)
end


function determineSpeed( )
     if keyStates.slow == 'down' then
          return 0.9
     elseif keyStates.fast == 'down' then
          return 50
     elseif keyStates.maxSpeed == 'down' then
          return 300
     end
     return 10
end


function computeMovement(dx, dy, dz, speed)
     local mx, my, mz = 0, 0, 0
     if keyStates.w == 'down' then
          mx, my, mz = mx + dx, my + dy, mz + dz
     end
     if keyStates.s == 'down' then
          mx, my, mz = mx - dx, my - dy, mz - dz
     end
     if keyStates.a == 'down' then
          mx, my = mx - dy, my + dx
     end
     if keyStates.d == 'down' then
          mx, my = mx + dy, my - dx
     end
     if keyStates.up == 'down' then
          mz = mz + 0.1 * speed
     end
     if keyStates.down == 'down' then
          mz = mz - 0.1 * speed
     end
     return {
          x = mx * 0.1 * speed,
          y = my * 0.1 * speed,
          z = mz * 0.1 * speed
     }
end