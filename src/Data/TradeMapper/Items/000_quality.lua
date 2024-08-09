return {
	id = "QUALITY",
	name = "Quality",
	run = function (item, modTrade, parseLineTrade)
		if item.quality and item.quality > 0 then
			modTrade:NewMod("MiscFilter", "quality", { min = item.quality })
		end	
	end
}