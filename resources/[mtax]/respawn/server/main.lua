

addEventHandler( 'onPlayerLogin', root, function( )
    setElementHealth( source, 100 )
    fadeCamera( source, false, 0.3 )
    setTimer( function( source )
        spawnPlayer( source, Vector3( unpack( config.spawnPlayer.pos ) ), config.spawnPlayer.rot, 0, 0, 0 )
        setCameraTarget( source )
        fadeCamera( source, true, 0.5 )
        Client.smoothCamera( false, source )
    end, 300, 1, source )
end)


addEventHandler( 'onPlayerJoin', root, function( )
    setCameraMatrix( source, unpack( config.cameras[ math.random( #config.cameras ) ] ) )
end)


addEventHandler( 'onPlayerWasted', root, function( )
    fadeCamera( source, false, 0.8 )
    setTimer( function( player )
        fadeCamera( player, true, 0.8 )
        setElementHealth( player, 100 )
        setCameraTarget( player, player )
        spawnPlayer( player, Vector3( unpack( config.spawnPlayer.pos ) ) , config.spawnPlayer.rot )
    end, 800, 1, source )
end)