
local connection = dbConnect( 'sqlite', 'binds.db' )

if connection then
    outputDebugString( '[admin] - Banco de dados ' .. getResourceName( getThisResource( ) ) .. ' conectado com sucesso', 4, 142, 124, 195)
    dbExec( connection, 'CREATE TABLE IF NOT EXISTS bindName ( account TEXT, bind TEXT, cmd TEXT )' )
else
    outputDebugString('[admin] - Banco de dados não encontrado', 4, 244, 67, 54)
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
    local acl = exports['acls']
    local acc = exports['accounts']
    if acl:isObjectInACLGroup( 'user.'..acc:getAccountName( acc:getPlayerAccount( client ) ), acl:aclGetGroup( 'Console' ) ) then
        return true
    end
    return false
end


Server.alpha = function( alpha )
    setElementAlpha( client, alpha )
    setElementCollisionsEnabled( client, alpha <= 0 and false or true )
    setElementFrozen( client, alpha <= 0 and true or false )
    setPlayerAnticheatEnabled( client, alpha <= 0 and false or true, 'movement' )
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


addEventHandler( 'onResourceStart', resourceRoot, function( )
    setTimer( function( )
        for i, v in ipairs( getElementsByType( 'player' ) ) do
            local account = exports['accounts']:getAccountName( exports['accounts']:getPlayerAccount( v ) )
            local result = dbPoll( dbQuery( connection, 'SELECT * FROM bindName WHERE account = ?', account ), -1 )
            if result and #result > 0 then
                for _, w in ipairs( result or { } ) do
                    Client.executeBind( false, v, w.bind, w.cmd )
                end
            end
        end
    end, 800, 1 )
end)