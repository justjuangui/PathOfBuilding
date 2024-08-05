if not loadStatFile then
	dofile("statdesc.lua")
end
loadStatFile("tincture_stat_descriptions.txt")

local dkjson = require "dkjson"

-- loading league
print("Downloading Stats info")

local function printScopeInfo(text)
	print(string.rep("=", 10))
	print(text)
	print(string.rep("=", 10))
end
local function cleanAndFormatString(str)
	return str:gsub('"', '\\"'):gsub("\n", "\\n"):gsub("%%", "%%%%"):gsub("%(", "%%("):gsub("%)", "%%)"):lower()
end

local function generateFunctionParseWithValues(out, outPrefix, entryText, modTradeId, negate, defaultValue) 
	negate = negate or false
	defaultValue = defaultValue or ''
	local paramIndex = defaultValue == '' and 0 or 1
	local strFunDefinition = 'function('
	local strFunBody = 'return {tradeId="'..modTradeId..'",values={' .. defaultValue

	-- we are mathinng 5, +5, -5, 0.5, -0.5, +0.5
	local textFormat = entryText:gsub("[+-]?#",function(k, val)
		strFunDefinition = strFunDefinition .. (paramIndex > 0 and ',' or '') .. 'num' .. paramIndex
		strFunBody = strFunBody .. (paramIndex > 0 and ',' or '') .. (negate and '-1*' or '') .. 'num'.. paramIndex
		paramIndex = paramIndex + 1
		return "([0-9.+-]+)"
	end)

	strFunDefinition = strFunDefinition .. ') '
	strFunBody = strFunBody .. '}} end'
	out:write(outPrefix ..'["'..textFormat..'"]='.. strFunDefinition..strFunBody..',\n')
end

local function findModItemWithMultipleStats(condFunc, modTrade,out, outPrefix)
	local statsProcessed = {}
	for mod in dat("Mods"):Rows() do
		if not condFunc(mod) then
			goto continue
		end

		-- validate why 6
		for i = 1, 6 do
			if mod["Stat"..i] then
				local statId = mod["Stat"..i].Id
				if not statsProcessed[statId] then
					statsProcessed[statId] = true
					
					local statsInfo = getInfoByStatId(statId)
					local suffix = (statId:match("local_") and " (local)" or '')

					if statsInfo and #statsInfo > 0 and #statsInfo[1] > 1 then
						local statInfo = statsInfo[1]

						-- handling increased word
						if #statInfo > 1 and statInfo[1].text:match("increased") and #statInfo[2] > 0 then
							local increasedStat = statInfo[1]
							local decreasedStat = statInfo[2]
							
							-- find the increased modTrade
							local formatIncreased = cleanAndFormatString(increasedStat.text:gsub("{[0]?}", "#"):lower())
							local formatDecreased = cleanAndFormatString(decreasedStat.text:gsub("{[0]?}", "#"):lower())

							if modTrade[formatIncreased..suffix] then
								local increasedTradeId = modTrade[formatIncreased..suffix]
								generateFunctionParseWithValues(out, outPrefix, formatDecreased..suffix, increasedTradeId, true, nil)
							elseif modTrade[formatDecreased..suffix] then
								local decreasedTradeId = modTrade[formatDecreased..suffix]	
								generateFunctionParseWithValues(out, outPrefix, formatIncreased..suffix, decreasedTradeId, false, nil)
							elseif modTrade[formatIncreased] then
								local increasedTradeId = modTrade[formatIncreased]	
								generateFunctionParseWithValues(out, outPrefix, formatDecreased, increasedTradeId, true, nil)
							elseif modTrade[formatDecreased] then
								local decreasedTradeId = modTrade[formatDecreased]	
								generateFunctionParseWithValues(out, outPrefix, formatIncreased, decreasedTradeId, false, nil)
							else
								print("==> ModTrade not found for increased mod with multiple stats: "..mod.Id .. " increased: "..increasedStat.text)
							end
						elseif #statInfo > 1 and not statInfo[1].text:match("{[0]?}") and statInfo[2].text:match("{[0]?}") then 
							-- handling stats that doesnt have any value placeholder in the first stat, but have a value placeholder in second
							local firstStat = statInfo[1]
							local secondStat = statInfo[2]
							
							
							-- find the increased modTrade
							local formatFirstStat = cleanAndFormatString(firstStat.text:lower())
							local formatSecondStat = cleanAndFormatString(secondStat.text:gsub("{[0]?}", "#"):lower())
							local defaultValue = tostring(firstStat.limit[1][1])
							
							if modTrade[formatSecondStat..suffix] then
								local secondTradeId = modTrade[formatSecondStat..suffix]
								generateFunctionParseWithValues(out, outPrefix, formatFirstStat..suffix, secondTradeId, false, defaultValue)
							elseif modTrade[formatSecondStat] then
								local secondTradeId = modTrade[formatSecondStat..suffix]
								generateFunctionParseWithValues(out, outPrefix, formatFirstStat, secondTradeId, false, defaultValue)
							else
								print("==> ModTrade not found for no place holder mod with multiple stats: "..mod.Id .. " placeholder: "..formatFirstStat)
							end

						else
							print("Skipping mod " .. mod.Id .. " with multiple stats: ".. statId)
						end
					end
				end
			end
		end

		::continue::
	end
end

launch:DownloadPage(
	"https://www.pathofexile.com/api/trade/data/stats",
	function(response, errMsg)
		if errMsg then
			return "POE ERROR", "Error: "..errMsg
		else
			local json_data = dkjson.decode(response.body)
			if not json_data then
				return "Failed to Get PoE stats"
			end

			local out = io.open("../Data/TradeStatsParser.lua", "w")
			out:write('-- This file is automatically generated, do not edit!\n')
			out:write('-- Trade parser data (c) Grinding Gear Games\n\nreturn {\n')
			for _, stat in pairs(json_data.result) do
				out:write('\t["'..stat.id..'"] = {\n')
				local cacheEntries = {}
				for _, entry in pairs(stat.entries) do
					local entriesToParse = {}
					
					if entry.text:find("\n") then
						for line in entry.text:gmatch("([^\n]+)") do
							table.insert(entriesToParse, line)
						end
					else
						table.insert(entriesToParse, entry.text)
					end

					for _, entryToParse in ipairs(entriesToParse) do
						local entryText = cleanAndFormatString(entryToParse)
						-- We need to map exact string
						-- # -> (d+)
						-- option
						if entry.option and entry.option.options then
							if entryText:find("#") then
								for _, option in ipairs(entry.option.options) do
									local optionsToParse = {}
									if option.text:find("\n") then
										for line in option.text:gmatch("([^\n]+)") do
											table.insert(optionsToParse, line)
										end
									else
										table.insert(optionsToParse, option.text)
									end

									for _, optionsToParse in ipairs(optionsToParse) do
										local textFormat = entryText:gsub("#", function(k, val)
											return cleanAndFormatString(optionsToParse)
										end)
										out:write('\t\t["'..textFormat..'"]={tradeId="'..entry.id..'", option=' .. option.id .. ',values={'..option.id..'}},\n')
									end
								end
							else
								print("Option with text: "..entryText.." has no # in it")
							end
						elseif entryText:find("#") then
							cacheEntries[entryText] = entry.id
							generateFunctionParseWithValues(out, "\t\t", entryText, entry.id, false)
						else				
							out:write('\t\t["'..entryText..'"]="'..entry.id..'",\n')
						end
					end
				end

				-- we are going to add mods with more that one entry in stat file
				if stat.id == "explicit" or stat.id == "fractured" then
					printScopeInfo("Parsing multiple stats for "..stat.id)
					findModItemWithMultipleStats(function(mod)
						-- only (items, flask and ticture) with prefix or suffix
						return ((mod.Domain == 1 or mod.Domain == 2) and (mod.GenerationType == 1 or mod.GenerationType == 2))
							or (mod.Domain == 36 and (mod.GenerationType == 1 or mod.GenerationType == 2 or mod.GenerationType == 3))
					end, cacheEntries, out, "\t\t")
				end

				out:write('\t},\n')
			end
			out:write('}')
			out:close()

			printScopeInfo("Stats info downloaded")
		end
	end
)