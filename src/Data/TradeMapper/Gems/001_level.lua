return {
	id = "LEVEL",
	name = "Level",
	run = function (gem, modTrade, parseLineTrade)
		if gem.level then
			modTrade:AddMod({name="MiscFilter", type="gem_level", value={ min = gem.level }, displayName="Level", enabled=true})
		end	
	end
}