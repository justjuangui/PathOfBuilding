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

			for _, mod in ipairs(item.explicitModLines) do
				local searchInLocal = false
				for  affix, isLocal in pairs(affixesList) do
					if mod.line:lower():match(affix) then
						searchInLocal = isLocal
						break
					end
				end

				local modTags = parseLineTrade(mod, "explicit", searchInLocal) -- search (Local) mods also
	
				if #modTags == 1 then
					local modTag = modTags[1]
					modTag.name = "StatsFilter" -- How to use Constant Here
					modTrade:AddMod(modTag)
				elseif searchInLocal and #modTags > 1 then
					for _, modTag in ipairs(modTags) do
						if modTag.line == "" then -- if line is empty, then it's a local tag
							modTag.name = "StatsFilter" -- How to use Constant Here
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
						table.insert(countStatsFilter.values, modTag)
					end

					modTrade:AddMod(countStatsFilter)
				end
			end
		end
	end
}