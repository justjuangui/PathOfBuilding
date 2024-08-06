return {
	id = "QUALITY",
	name = "Quality",
	run = function (gem, modTrade, parseLineTrade)
		if gem.quality then
			modTrade:NewMod("MiscFilter", "quality", { min = gem.quality })
		end	
	end
}