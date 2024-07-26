local dkjson = require "dkjson"
local s_format = string.format
local s_gsub = string.gsub
local s_byte = string.byte
local t_insert = table.insert

-- Scan a line for the earliest and longest match from the pattern list
-- If a match is found, returns the corresponding value from the pattern list, plus the remainder of the line and a table of captures
local function scanTrade(line, patternList, plain)
	local bestIndex, bestEndIndex
	local bestPattern = ""
	local bestVal, bestStart, bestEnd, bestCaps
	local lineLower = line:lower()
	for pattern, patternVal in pairs(patternList) do
		local index, endIndex, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1, plain)
		if index and (not bestIndex or index < bestIndex or (index == bestIndex and (endIndex > bestEndIndex or (endIndex == bestEndIndex and #pattern > #bestPattern)))) then
			bestIndex = index
			bestEndIndex = endIndex
			bestPattern = pattern
			bestVal = patternVal
			bestStart = index
			bestEnd = endIndex
			bestCaps = { cap1, cap2, cap3, cap4, cap5 }
		end
	end
	if bestVal then
		return bestVal, line:sub(1, bestStart - 1) .. line:sub(bestEnd + 1, -1), bestCaps
	else
		return nil, line
	end
end

local function parseLineTrade(mod, whereDefault)
	if not whereDefault then whereDefault = "explicit" end

	local where = whereDefault ~= "enchant" and ((mod.fractured and "fractured") or (mod.crafted and "crafted")) or whereDefault
	modTag, line, tagCap = scanTrade(mod.line, data.tradeInfo.Stats[where], nil)
	if type(modTag) == "function" then
		modTag = modTag(unpack(tagCap))
	elseif type(modTag) == "string" then
		modTag = { tradeId = modTag }
	end

	if not modTag then
		print("No tradeInfo found for line: " .. line .. " in " ..  where)
	end

	return modTag
end

local BaseMapperClass = newClass("TradeBaseMapper", function(self, folderPath)
	self.folderPath = folderPath
	self.rules = {}

	local handle = NewFileSearch(folderPath.."/*.lua")
	while handle do
		local fileName = handle:GetFileName()
		local errMsg, rule
		errMsg, rule = PLoadModule(folderPath.."/"..fileName)

		if errMsg then
			print("Error loading rule file: "..errMsg)
		else
			t_insert(self.rules, rule)
		end

		if not handle:NextFile() then
			break
		end
	end
end)

function BaseMapperClass:GenerateModTradeBasic()
	local modsTrade = new("ModDB")
	modsTrade:NewMod("NameFilter")
	modsTrade:NewMod("TypeFilter")
	modsTrade:NewMod("WeaponFilter")
	modsTrade:NewMod("ArmourFilter")
	modsTrade:NewMod("MiscFilter")
	modsTrade:NewMod("StatsFilter")
	return modsTrade
end

function BaseMapperClass:Execute(objRef, excludeRuleList)
	local modsTrade = self:GenerateModTradeBasic()
	for _, rule in ipairs(self.rules) do
		if not excludeRuleList or not excludeRuleList[rule.id] then
			local errMsg = PCall(rule.run, objRef, modsTrade, parseLineTrade)

			if errMsg then
				print("Error executing rule: "..errMsg)
			end
		end
	end
	return modsTrade
end

function BaseMapperClass:GetRules()
	local rulesNames = {}
	for _, rule in ipairs(self.rules) do
		if rule.name then
			t_insert(rulesNames, { name = rule.name,  id = rule.id})
		end
	end
	return rulesNames
end

local TradeGeneratorClass = newClass("TradeGenerator", function(self)
	self.itemMapper = new("TradeBaseMapper", "Data/TradeMapper/Items")
	
end)
function TradeGeneratorClass:GenerateExactMatchTradeLink(testItem, excludeRuleList)
	if launch.devMode then
		self.itemMapper = new("TradeBaseMapper", "Data/TradeMapper/Items")
	end

	local modTrade = self.itemMapper:Execute(testItem, excludeRuleList)

	local search = {
		query = {
			status = {
				option = "online"
			},
		},
		filters = {},
		sort = {
			price = "asc"
		}
	}

	local modName = modTrade.mods['NameFilter']

	if #modName > 1 then
		for index, mod in ipairs(modName) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item

			search.query[mod.type] = mod.value
			::continue::
		end
	end

	local modMisc = modTrade.mods['MiscFilter']

	if #modMisc > 1 then
		if not search.query.filters then
			search.query.filters = {}
		end
		if not search.query.filters.misc_filters then
			search.query.filters.misc_filters = {}
		end
		if not search.query.filters.misc_filters.filters then
			search.query.filters.misc_filters.filters = {}
		end

		for index, mod in ipairs(modMisc) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item

			search.query.filters.misc_filters.filters[mod.type] = mod.value
			::continue::
		end
	end

	local modStats = modTrade.mods['StatsFilter']

	if #modStats > 1 then
		if not search.query.stats then
			search.query.stats = {}
		end

		local aStats = {}
		for index, stat in ipairs(modStats) do
			if index == 1 then goto continue end -- Skip the first stat, as it is the name of the item

			t_insert(aStats, {
				id = stat.tradeId,
				value = stat.values and #stat.values> 0 and {
					min = #stat.values > 0 and stat.values[1] or nil,
					max = #stat.values > 1 and stat.values[2] or nil,
					option = stat.option or nil
				} or nil
			})

			::continue::
		end


		t_insert(search.query.stats, {
			type = "and",
			filters = aStats
		})
	end

	OpenURL("https://www.pathofexile.com/trade/search/?q=" .. (s_gsub(dkjson.encode(search), "[^a-zA-Z0-9]", function(a)
		return s_format("%%%02X", s_byte(a))
	end)))
end

function TradeGeneratorClass:GeneratePopupItemSettings(callback)
	local controls = {}
	local excludeRuleList = {}
	local previousItem = nil
	local height = 30
	local width = 300

	for _, rule in ipairs(self.itemMapper:GetRules()) do
		local anchor = (previousItem and {"TOPRIGHT", previousItem, "BOTTOMRIGHT"}) or nil
		local xPos = not previousItem and 20 or 0
		local yPos = not previousItem and height or 2
		controls[rule.id] = new("CheckBoxControl", anchor, xPos, yPos, 18, rule.name, function(state)
			excludeRuleList[rule.id] = not state or nil
		end, nil, true)
		previousItem = controls[rule.id]
		height = height + 20
	end

	height = height + 18
	controls.generate = new("ButtonControl", {"TOPLEFT", nil, "TOPLEFT"} , (width / 2) - 120 - (6/2),height, 120, 20, "Open Trade Link", function()
		callback(excludeRuleList)
		main:ClosePopup()
	end)
	
	controls.close = new("ButtonControl", {"TOPLEFT", controls.generate, "TOPRIGHT"}, 6, 0, 120, 20, "Cancel", function()
		main:ClosePopup()
	end)
	
	height = height + 38
	main:OpenPopup(300, height, "Item trade rules", controls, nil, nil, "close", nil, nil)
end