
addEventHandler( 'onPlayerLogin', root, function( )
    setElementHealth( source, 100 )
    fadeCamera( source, false, 0.3 )
    setTimer( function( source )
        spawnPlayer( source, Vector3( unpack( config.spawnPlayer.pos ) ), config.spawnPlayer.rot, 0, 0, 0 )
        setCameraTarget( source )
        fadeCamera( source, true, 0.5 )
        Client.smoothCamera( false, source )
        setPedStat( source, 22, 0 )
    end, 300, 1, source )
end)


addEventHandler( 'onPlayerJoin', root, function( )
    local cameras = {
        { 2522.2014160156, -1658.0786132812, 18.968399047852, 2521.3056640625, -1658.5151367188, 18.884963989258 },
        { 465.46618652344, -2128.3159179688, 26.842199325562, 464.92199707031, -2127.4777832031, 26.803146362305 }
    }
    setCameraMatrix( source, unpack( cameras[ math.random( #cameras ) ] ) )
end)