return {
	id = "IMPLICITS",
	name = "Implicits",
	run = function (item, modTrade, parseLineTrade)
		if item.implicitModLines and #item.implicitModLines > 0 then
			for _, mod in ipairs(item.implicitModLines) do
				local modTag = parseLineTrade(mod, "implicit")
	
				if modTag then
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}