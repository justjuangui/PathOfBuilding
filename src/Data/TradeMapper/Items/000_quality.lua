return {
	id = "QUALITY",
	name = "Quality",
	run = function (item, modTrade, parseLineTrade)
		if item.quality then
			modTrade:NewMod("MiscFilter", "quality", { min = item.quality })
		end	
	end
}