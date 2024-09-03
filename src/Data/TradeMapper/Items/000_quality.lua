return {
	id = "QUALITY",
	name = "Quality",
	run = function (item, modTrade, parseLineTrade)
		if item.quality and item.quality > 0 then
			modTrade:AddMod({name="MiscFilter", type="quality", value={ min = item.quality }, displayName="Quality", enabled=true})
		end	
	end
}