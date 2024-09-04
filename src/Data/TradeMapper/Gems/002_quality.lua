return {
	id = "QUALITY",
	name = "Quality",
	run = function (gem, modTrade, parseLineTrade)
		if gem.quality and gem.quality > 0 then
			modTrade:AddMod({name="MiscFilter", type="quality", value={ min = gem.quality }, displayName="Quality", enabled=gem.quality >= 20})
		end	
	end
}