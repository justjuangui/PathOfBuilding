return {
	id = "ENCHANT",
	name = "Enchant",
	run = function (item, modTrade, parseLineTrade)
		if item.enchantModLines and #item.enchantModLines > 0 then
			for _, mod in ipairs(item.enchantModLines) do
				local modTag = parseLineTrade(mod, "enchant")
	
				if modTag then
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}