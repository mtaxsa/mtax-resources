local visible = false
local debug = { }
local debugLevel = {
    [ 1 ] = 'erro',
    [ 2 ] = 'debug',
    [ 3 ] = 'success',
}

Toggle = function( )
    visible = not visible
    sendNuiMessage({ action = 'toggle', data = visible })
    setNuiFocus( visible, visible )
end


addCommandHandler( 'debug', function( )
    Toggle( )
end)


addEventHandler( 'onClientDebugMessage', root, function( mensagem, nivel, arquivo, linha )
    if visible then
        table.insert( debug, { level = debugLevel[ nivel ], text = mensagem, side = 'client' } )
    end
end)



addEvent( 'onDebugMessage', true )
addEventHandler( 'onDebugMessage', resourceRoot, function( mensagem, nivel, arquivo, linha )
    if visible then
        table.insert( debug, { level = debugLevel[ nivel ], text = mensagem, side = 'server' } )
    end
end)


setTimer( function( )
    if visible then
        for i, v in ipairs( debug or { } ) do
            sendNuiMessage({ action = 'addLog', data = v })
        end
        debug = { }
    end
end, 3000, 0 )