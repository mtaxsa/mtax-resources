
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



---# Teste


addCommandHandler( 'log', function( )
    logDiscord( )
end)

logDiscord = function( )
    embed( {
        title = 'titulo';
        webhook_link = 'https://discord.com/api/webhooks/1494411418114719896/hqG_ZEzVFl0nVDPFOhqBrUgXiIpulMeNpaCGBYCOePmYvU0O4TzEtW6-OYGjsJeDC9mu';
        description = 'oieoeioeieieieie';
        gif = 'https://i.imgur.com/eBKLuFs.jpeg';
        color = 5763719;
        copyright = 'MTAX'
    } )
end


embed = function( infos )
     if infos and type( infos ) == 'table' then
          local dados = {
               embeds = { 
                    {
                         title = infos.title,
                         color = infos.color,
                         description = infos.description,
                         image = {
                              url = infos.gif,
                         },
                         footer = {
                              text = infos.copyright,
                         },
                    },
               }
          }
          webhook = tostring(infos.webhook_link)
          dados = toJSON(dados)
          dados = dados:sub(2, -2)
          local opt = {
               connectionAttempts = 5,
               connectTimeout = 7000,
               headers = {
                    ["Content-Type"] = "application/json"
               },
               postData = dados
          }
          fetchRemote(webhook, opt, function( ... ) 
            iprint( ... )
          end)
     end
end