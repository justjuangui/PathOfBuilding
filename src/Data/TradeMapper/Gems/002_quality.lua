return {
	id = "QUALITY",
	name = "Quality",
	run = function (gem, modTrade, parseLineTrade)
		if gem.quality then
			modTrade:AddMod({name="MiscFilter", type="quality", value={ min = gem.quality }, displayName="Quality", enabled=true})
		end	
	end
}