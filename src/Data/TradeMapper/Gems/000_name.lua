return {
	id = "NAME",
	name = "Name",
	run = function (gem, modTrade, parseLineTrade)
		if gem.nameSpec then
			local gemName = gem.nameSpec
			if gem.supportEffect and gem.skillId:match("Support") then
				gemName = gemName .. " Support"
			end
			modTrade:NewMod("NameFilter", "type", gemName)
		end	
	end
}