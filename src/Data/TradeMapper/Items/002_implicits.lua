return {
	id = "IMPLICITS",
	name = "Implicits",
	run = function (item, modTrade, parseLineTrade, parseRangeOrCustom)
		if item.implicitModLines and #item.implicitModLines > 0 then

			local variantKeys = {"variant", "variantAlt", "variantAlt2", "variantAlt3", "variantAlt4", "variantAlt5"}
			for _, mod in ipairs(item.implicitModLines) do
				local colorCode = (mod.exarch and colorCodes.CLEANSING) or (mod.eater and colorCodes.TANGLE) or (item.corrupted and colorCodes.NEGATIVE) or colorCodes.MAGIC
				local displayName = colorCode .. "Implicits"
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

				local modTags = parseLineTrade(mod, "implicit")

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
						print("No tradeInfo found for line: " .. modLine .. " in implicit")
					else
						modTrade:AddMod(countStatsFilter)
					end
				else
					print("No tradeInfo found for line: " .. modLine .. " in implicit")
				end

				::nextmod::
			end
		end
	end
}