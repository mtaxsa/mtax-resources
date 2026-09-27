


addCommandHandler( 'register', function( cmd, account, password )
    Server.registerAccount( false, account, password )
end)


addCommandHandler( 'login', function( cmd, account, password )
    Server.logIn( false, account, password )
end)


addCommandHandler( 'logout', function()
    Server.logOut( false )
end)


addCommandHandler( 'myaccount', function(  )
    Server.account( function( account )
        iprint( account )
    end)
end)


local money = 0
local serial = false

local function toMoney( amount )
    amount = tonumber( amount )
    if not amount then
        return false
    end

    return math.tointeger( ( math.modf( amount ) ) ) or false
end


addEventHandler( 'onClientResourceStart', resourceRoot, function( )
    Server.getPlayerMoney( function( amount )
        money = toMoney( amount ) or 0
    end )
    Server.getPlayerSerial( function( value )
        serial = type( value ) == 'string' and value or false
    end )
end )


Client.money = function( amount )
    money = toMoney( amount ) or 0
end


getPlayerMoney = function( element )
    if element ~= nil and element ~= localPlayer then
        return false
    end
    return money
end


setPlayerMoney = function( amount, instant )
    amount = toMoney( amount )
    if not amount or ( instant ~= nil and type( instant ) ~= 'boolean' ) then
        return false
    end
    money = amount
    return true
end


givePlayerMoney = function( amount )
    amount = toMoney( amount )
    if not amount then
        return false
    end
    money = money + amount
    return true
end


takePlayerMoney = function( amount )
    amount = toMoney( amount )
    if not amount then
        return false
    end
    money = money - amount
    return true
end


getPlayerSerial = function( )
    return serial
end
