local visible = false
local tupdate = false


Toggle = function( )
    visible = not visible
    sendNuiMessage({ action = 'toggle', data = visible })
    Server.setStatsVisible( false, visible )
    if visible then
        tupdate = setTimer( function( )
            local _, rows_client = getPerformanceStats( 'Lua timing' )
            sendNuiMessage({ action = 'stats:client', data = rows_client })
        end, 1000, 0 )
    else
        if isTimer( tupdate ) then
            killTimer( tupdate )
        end
    end
end


Client.stats = function( rows )
    sendNuiMessage({ action = 'stats:server', data = rows })
end


addCommandHandler( 'cpu', function( )
    Server.checkACL( function( isAuthorized )
        if isAuthorized then
            Toggle( )
        end
    end)
end)