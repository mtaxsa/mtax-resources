
local connection = dbConnect( 'sqlite', 'binds.db' )

if connection then
    outputDebugString( '[admin] - Database ' .. getResourceName( getThisResource( ) ) .. ' successfully connected.', 4, 142, 124, 195)
    dbExec( connection, 'CREATE TABLE IF NOT EXISTS bindName ( account TEXT, bind TEXT, cmd TEXT )' )
else
    outputDebugString('[admin] - Database not found', 4, 244, 67, 54)
    stopResource( getThisResource( ) )
end


Server.saveBind = function( bind, cmd )
    local acc = exports['accounts']
    local account = acc:getAccountName( acc:getPlayerAccount( client ) )
    if not account then
        return false
    end
    local result = dbPoll( dbQuery( connection, 'SELECT * FROM bindName WHERE account = ? AND bind = ?', account, bind ), -1 )
    if result and #result <= 0 then
        dbExec( connection, 'INSERT INTO bindName ( account, bind, cmd ) VALUES ( ?, ?, ? )', account, bind, cmd )
    end
    return bind, cmd
end


Server.fly = function( )
    return true
end


addEvent( 'onPlayerLogin', true )
addEventHandler( 'onPlayerLogin', root, function( player, account )
    local result = dbPoll( dbQuery( connection, 'SELECT * FROM bindName WHERE account = ?', account ), -1 )
    if result and #result > 0 then
        for _, v in ipairs( result or { } ) do
            Client.executeBind( false, player, v.bind, v.cmd )
        end
    end
end)