
local watchers = { }


Server.checkACL = function( )
    local acl = exports['acls']
    local acc = exports['accounts']
    if acl:isObjectInACLGroup( 'user.'..acc:getAccountName( acc:getPlayerAccount( client ) ), acl:aclGetGroup( 'Console' ) ) then
        return true
    end
    return false
end


Server.setStatsVisible = function( visible )
    if isTimer( watchers[ client ] ) then
        killTimer( watchers[ client ] )
        watchers[ client ] = nil
    end
    if visible then
        watchers[ client ] = setTimer( function( player )
            if not isElement( player ) then
                return
            end
            local _, rows_server = getPerformanceStats( 'Lua timing' )
            Client.stats( false, player, rows_server )
        end, 1000, 0, client )
    end
end


addEventHandler( 'onPlayerQuit', root, function( )
    if isTimer( watchers[ source ] ) then
        killTimer( watchers[ source ] )
    end
    watchers[ source ] = nil
end)