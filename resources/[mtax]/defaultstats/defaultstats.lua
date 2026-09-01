defaultStats = {
	[69] = 500,  -- Pistol
	[70] = 999,  -- Silenced pistol
	[71] = 999,  -- Desert eagle
	[72] = 999,  -- Shotgun
	[73] = 500,  -- Sawnoff, 999 for duel wield
	[74] = 999,  -- Spas-12
	[75] = 500,  -- Micro-uzi & Tec-9, 999 for duel wield
	[76] = 999,  -- MP5
	[77] = 999,  -- AK-47
	[78] = 999,  -- M4
	[79] = 999,  -- Sniper rifle & country rifle
	[160] = 999, -- Driving
	[229] = 0, 	 -- Biking
	[230] = 999  -- Cycling
}

function setDefaultPlayerStats(player)
	for stat, value in pairs(defaultStats) do
		setPedStat(player, stat, value)
	end
end

function setStatsonJoin()
	setDefaultPlayerStats(source)
end
addEventHandler("onPlayerJoin", root, setStatsonJoin)

function onStartSetStats()
	for i, v in pairs(getElementsByType("player")) do
		setDefaultPlayerStats(v)
	end
end
addEventHandler("onResourceStart", resourceRoot, onStartSetStats)