return {
	id = "ENCHANT",
	name = "Enchant",
	run = function (item, modTrade, parseLineTrade, parseRangeOrCustom)
		if item.enchantModLines and #item.enchantModLines > 0 then
			local variantKeys = {"variant", "variantAlt", "variantAlt2", "variantAlt3", "variantAlt4", "variantAlt5"}
			for _, mod in ipairs(item.enchantModLines) do
				local colorCode = (mod.crafted and colorCodes.CRAFTED) or (mod.scourge and colorCodes.SCOURGE) or (mod.custom and colorCodes.CUSTOM) or (mod.fractured and colorCodes.FRACTURED) or (mod.crucible and colorCodes.CRUCIBLE) or colorCodes.MAGIC
				local displayName = colorCode .. "Enchant"
				if mod.variantList then
					local variantFound  = false
					for _, key in ipairs(variantKeys) do
						if item[key] then
							if mod.variantList[item[key]] then
								variantFound =  true
							end
						end
					end

					if not variantFound then
						goto nextmod
					end
				end

				local modLine = mod.line:gsub("\n", "")
				modLine = parseRangeOrCustom(mod, modLine)

				local modTags = parseLineTrade(mod, "enchant")

				if #modTags == 1 then
					local modTag = modTags[1]
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTag.displayName = displayName
					modTag.displayValue = colorCode .. modLine
					modTag.enabled = true
					modTrade:AddMod(modTag)
				elseif #modTags > 1 then
					local countStatsFilter = {
						min = 1,
						values = {},
						name = "StatsFilterCounts"
					}

					for _, modTag in ipairs(modTags) do
						if modTag.line == "" and modTag.index == 1 then
							modTag.displayName = displayName
							modTag.displayValue = colorCode .. modLine
							modTag.enabled = true
							table.insert(countStatsFilter.values, modTag)
						end
					end

					if #countStatsFilter.values == 1 then
						countStatsFilter.values[1].name = "StatsFilter"
						countStatsFilter.values[1].displayName = displayName
						countStatsFilter.values[1].displayValue = colorCode .. modLine
						countStatsFilter.values[1].enabled = true
						modTrade:AddMod(countStatsFilter.values[1])
					elseif #countStatsFilter.values == 0 then
						print("No tradeInfo found for line: " .. modLine .. " in enchant")
					else
						modTrade:AddMod(countStatsFilter)
					end
				else
					print("No tradeInfo found for line: " .. modLine .. " in enchant")
				end
				::nextmod::
			end
		end
	end
}