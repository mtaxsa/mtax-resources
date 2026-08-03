--# onDebugMessage

addEventHandler( 'onDebugMessage', root, function( mensagem, nivel, arquivo, linha )
    triggerClientEvent( 'onDebugMessage', resourceRoot, mensagem, nivel, arquivo, linha )
end)