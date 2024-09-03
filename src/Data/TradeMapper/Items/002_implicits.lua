return {
	id = "IMPLICITS",
	name = "Implicits",
	run = function (item, modTrade, parseLineTrade)
		if item.implicitModLines and #item.implicitModLines > 0 then
			for _, mod in ipairs(item.implicitModLines) do
				local colorCode = (mod.crafted and colorCodes.CRAFTED) or (mod.scourge and colorCodes.SCOURGE) or (mod.custom and colorCodes.CUSTOM) or (mod.fractured and colorCodes.FRACTURED) or (mod.crucible and colorCodes.CRUCIBLE) or colorCodes.MAGIC
				local modTags = parseLineTrade(mod, "implicit")

				for _, modTag in ipairs(modTags) do
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTag.displayName = colorCode .. "Implicit"
					modTag.displayValue = colorCode .. mod.line
					modTag.enabled = true
					modTrade:AddMod(modTag)
				end
			end
		end
	end
}