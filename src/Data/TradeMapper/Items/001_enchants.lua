return {
	id = "ENCHANT",
	name = "Enchant",
	run = function (item, modTrade, parseLineTrade)
		if item.enchantModLines and #item.enchantModLines > 0 then
			for _, mod in ipairs(item.enchantModLines) do
				local modTags = parseLineTrade(mod, "enchant")

				for _, modTag in ipairs(modTags) do
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}