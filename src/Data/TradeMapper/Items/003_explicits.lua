return {
	id = "EXPLICITS",
	name = "Explicits",
	run = function (item, modTrade, parseLineTrade)
		if item.explicitModLines and #item.explicitModLines > 0 then
			-- validate if base and filter affix, then lookcup for "local tag"
			local affixesList = {}			
			for modId, mod in pairs(item.affixes) do
				if (mod.type == "Prefix" or mod.type == "Suffix") and item:GetModSpawnWeight(mod) > 0 and not item:CheckIfModIsDelve(mod) then
					for _, name in ipairs(mod) do
						local formatedName = name:gsub("%%", "%%%%"):lower():gsub("[+-]?%(%d+%-%d+%)", function(k, val)
							return "([0-9.+-]+)"
						end)
						affixesList[formatedName] = modId:lower():match("local") and true or false
					end
				end
			end

			local variantKeys = {"variant", "variantAlt", "variantAlt2", "variantAlt3", "variantAlt4", "variantAlt5"}

			for _, mod in ipairs(item.explicitModLines) do
				local colorCode = (mod.crafted and colorCodes.CRAFTED) or (mod.scourge and colorCodes.SCOURGE) or (mod.custom and colorCodes.CUSTOM) or (mod.fractured and colorCodes.FRACTURED) or (mod.crucible and colorCodes.CRUCIBLE) or colorCodes.MAGIC
				local displayName = colorCode .. ((mod.crafted and "Crafted") or (mod.custom and "Custom") or (mod.scourge and "Scourge") or (mod.fractured and "Fractured") or (mod.cricible and "Crucible") or "Explicit")
				
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

				local searchInLocal = false
				local modLine = mod.line
				
				if mod.crafted or mod.custom or modLine:gmatch("[+-]?%(%d+%-%d+%)") then
					modLine = modLine:gsub("%(%d+%-%d+%)", function (k, val)
						return mod.modList and #mod.modList > 0 and mod.modList[1].value or val
					end)
				end
				for  affix, isLocal in pairs(affixesList) do
					if modLine:lower():match(affix) then
						searchInLocal = isLocal
						break
					end
				end

				local modTags = parseLineTrade(mod, "explicit", searchInLocal) -- search (Local) mods also
	
				if #modTags == 1 then
					local modTag = modTags[1]
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTag.displayName = displayName
					modTag.displayValue = colorCode .. modLine
					modTag.enabled = true
					modTrade:AddMod(modTag)
				elseif searchInLocal and #modTags > 1 then
					for _, modTag in ipairs(modTags) do
						if modTag.line == "" then -- if line is empty, then it's a local tag
							modTag.name = "StatsFilter" -- How to use Constant Here
							modTag.displayName = displayName
							modTag.displayValue = colorCode .. modLine
							modTag.enabled = true
							modTrade:AddMod(modTag)
						end
					end
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
					else
						modTrade:AddMod(countStatsFilter)
					end
				end

				::nextmod::
			end
		end
	end
}