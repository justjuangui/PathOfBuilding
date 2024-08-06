return {
	id = "LEVEL",
	name = "Level",
	run = function (gem, modTrade, parseLineTrade)
		if gem.level then
			modTrade:NewMod("MiscFilter", "gem_level", { min = gem.level })
		end	
	end
}