return {
	id = "EXPLICITS",
	name = "Explicits",
	run = function (item, modTrade, parseLineTrade)
		if item.explicitModLines and #item.explicitModLines > 0 then
			for _, mod in ipairs(item.explicitModLines) do
				local modTag = parseLineTrade(mod, "explicit")
	
				if modTag then
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}