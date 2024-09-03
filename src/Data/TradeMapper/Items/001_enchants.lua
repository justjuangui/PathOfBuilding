return {
	id = "ENCHANT",
	name = "Enchant",
	run = function (item, modTrade, parseLineTrade)
		if item.enchantModLines and #item.enchantModLines > 0 then
			for _, mod in ipairs(item.enchantModLines) do
				local colorCode = (mod.crafted and colorCodes.CRAFTED) or (mod.scourge and colorCodes.SCOURGE) or (mod.custom and colorCodes.CUSTOM) or (mod.fractured and colorCodes.FRACTURED) or (mod.crucible and colorCodes.CRUCIBLE) or colorCodes.MAGIC
				local modTags = parseLineTrade(mod, "enchant")

				for _, modTag in ipairs(modTags) do
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTag.displayName = colorCode .. "Enchant"
					modTag.displayValue = colorCode .. mod.line
					modTag.enabled = true
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}