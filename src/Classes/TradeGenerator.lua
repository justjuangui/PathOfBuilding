local dkjson = require "dkjson"
local s_format = string.format
local s_gsub = string.gsub
local s_byte = string.byte
local t_insert = table.insert

-- Scan a line for the earliest and longest match from the pattern list
-- If a match is found, returns the corresponding value from the pattern list, plus the remainder of the line and a table of captures
local function scanTrade(line, patternList, plain)
	local lineLower = line:lower()
	local found = {}
	for _, patternInfo in ipairs(patternList) do
		local pattern = patternInfo.l
		local patternVal = patternInfo.val
		local index, endIndex, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1, plain)
		if index then
			table.insert(found, {
				modTag = patternVal,
				line = line:sub(1, index - 1) .. line:sub(endIndex + 1, -1),
				index = index,
				caps = { cap1, cap2, cap3, cap4, cap5 }
			})
		end
	end

	return found
end

local function parseLineTrade(mod, whereDefault, isLocal)
	if not whereDefault then whereDefault = "explicit" end
	
	local where = whereDefault ~= "enchant" and ((mod.fractured and "fractured") or (mod.crafted and "crafted")) or whereDefault

	local modLine = mod.line .. (isLocal and " (local)" or "") -- add local tag to line

	if modLine:find("\n") then
		local pos = 0
		for s in modLine:gmatch("([^\n]+)") do
			if pos == 0 then
				modLine = s
			end
			pos = pos + 1
		end
	end

	-- handle custom craft with range
	if mod.crafted or mod.custom or modLine:gmatch("%(%d+%-%d+%)") then
		modLine = modLine:gsub("%(%d+%-%d+%)", function (k, val)
			return mod.modList and #mod.modList > 0 and mod.modList[1].value or val
		end)
	end

	local foundTags = scanTrade(modLine, data.tradeInfo.Stats[where], nil)
	local tradeMods = {}

	if (#foundTags == 0) then
		print("No tradeInfo found for line: " .. modLine .. " in " ..  where)
		return tradeMods
	end	

	for _, found in ipairs(foundTags) do
		local modTag = found.modTag
		local tagCap = found.caps

		if type(modTag) == "function" then
			modTag = modTag(unpack(tagCap))
		elseif type(modTag) == "string" then
			modTag = { tradeId = modTag }
		end

		modTag.line = found.line
		modTag.index = found.index
		table.insert(tradeMods, modTag)
	end

	return tradeMods
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
	modsTrade:NewMod("SocketFilter")
	modsTrade:NewMod("MiscFilter")
	modsTrade:NewMod("StatsFilter")
	modsTrade:NewMod("StatsFilterCounts")	
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
	self.gemMapper = new("TradeBaseMapper", "Data/TradeMapper/Gems")
	
end)
function TradeGeneratorClass:GenerateExactMatchTradeLink(ObjectToMap, excludeRuleList, type)
	if launch.devMode then		
		self.itemMapper = new("TradeBaseMapper", "Data/TradeMapper/Items")
		self.gemMapper = new("TradeBaseMapper", "Data/TradeMapper/Gems")
	end

	if not excludeRuleList then
		excludeRuleList = {SOCKETSLINKS=true, SOCKETSSLOTS=true}
	end

	type = type or "items"
	local mapper = type == "gems" and self.gemMapper or self.itemMapper

	local modTrade = mapper:Execute(ObjectToMap, excludeRuleList)

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

	local modSocket = modTrade.mods['SocketFilter']

	if #modSocket > 1 then
		if not search.query.filters then
			search.query.filters = {}
		end
		if not search.query.filters.socket_filters then
			search.query.filters.socket_filters = {}
		end
		if not search.query.filters.socket_filters.filters then
			search.query.filters.socket_filters.filters = {}
		end

		for index, mod in ipairs(modSocket) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item

			search.query.filters.socket_filters.filters[mod.type] = mod.value
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

	local modStatsCounts = modTrade.mods['StatsFilterCounts']

	if #modStatsCounts > 1 then
		if not search.query.stats then
			search.query.stats = {}
		end

		for index, orGroup in ipairs(modStatsCounts) do
			if index == 1 then goto continue end -- Skip the first stat, as it is the name of the item
			
			local aStats = {}
			for _, stat in ipairs(orGroup.values) do
				t_insert(aStats, {
					id = stat.tradeId,
					value = stat.values and #stat.values> 0 and {
						min = #stat.values > 0 and stat.values[1] or nil,
						max = #stat.values > 1 and stat.values[2] or nil,
						option = stat.option or nil
					} or nil
				})
			end

			t_insert(search.query.stats, {
				type = "count",
				value = {
					min = orGroup.min,
					max = orGroup.max
				},
				filters = aStats
			})
			::continue::
		end
	end

	OpenURL("https://www.pathofexile.com/trade/search/?q=" .. (s_gsub(dkjson.encode(search), "[^a-zA-Z0-9]", function(a)
		return s_format("%%%02X", s_byte(a))
	end)))
end

function TradeGeneratorClass:GeneratePopupItemSettings(callback, type)
	local controls = {}
	local excludeRuleList = {SOCKETSLINKS=true, SOCKETSSLOTS=true}
	local previousItem = nil
	local height = 30
	local width = 300
	type = type or "items"
	local mapper = type == "gems" and self.gemMapper or self.itemMapper
	local title = type == "gems" and "Gem trade rules" or "Item trade rules"

	for _, rule in ipairs(mapper:GetRules()) do
		local anchor = (previousItem and {"TOPRIGHT", previousItem, "BOTTOMRIGHT"}) or nil
		local xPos = not previousItem and 20 or 0
		local yPos = not previousItem and height or 2
		local initialState = true
		if excludeRuleList[rule.id] then
			initialState = false
		end
		controls[rule.id] = new("CheckBoxControl", anchor, xPos, yPos, 18, rule.name, function(state)
			excludeRuleList[rule.id] = not state or nil
		end, nil, initialState)
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
	main:OpenPopup(300, height, title, controls, nil, nil, "close", nil, nil)
end