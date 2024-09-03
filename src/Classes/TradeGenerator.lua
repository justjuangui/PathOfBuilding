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

local function parseRangeOrCustom(mod, modLine)
	if modLine:find("\n") then
		local pos = 0
		for s in modLine:gmatch("([^\n]+)") do
			if pos == 0 then
				modLine = s
			end
			pos = pos + 1
		end
	end

	modLine = mod.range and itemLib.applyRange(modLine, mod.range, mod.valueScalar) or modLine

	return modLine
end

local function parseLineTrade(mod, whereDefault, isLocal)
	if not whereDefault then whereDefault = "explicit" end
	
	local where = whereDefault ~= "enchant" and ((mod.fractured and "fractured") or (mod.crafted and "crafted")) or whereDefault

	local modLine = mod.line .. (isLocal and " (local)" or "") -- add local tag to line

	modLine = parseRangeOrCustom(mod, modLine)

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
	modsTrade:AddMod({name="NameFilter", display="Name filter"})
	modsTrade:AddMod({name="TypeFilter", display="Type filters"})
	modsTrade:AddMod({name="WeaponFilter", display="Weapon filters"})
	modsTrade:AddMod({name="ArmourFilter", display="Armour filters"})
	modsTrade:AddMod({name="SocketFilter", display="Socket filters"})
	modsTrade:AddMod({name="MiscFilter", display="Misc filters"})
	modsTrade:AddMod({name="StatsFilter", display="Stats filters"})
	modsTrade:AddMod({name="StatsFilterCounts" , display="Count filter"})

	return modsTrade
end

function BaseMapperClass:Execute(objRef, excludeRuleList)
	local modsTrade = self:GenerateModTradeBasic()
	for _, rule in ipairs(self.rules) do
		if not excludeRuleList or not excludeRuleList[rule.id] then
			local errMsg = PCall(rule.run, objRef, modsTrade, parseLineTrade, parseRangeOrCustom)

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
	local modTrade = self:ParserObjectToMap(ObjectToMap, excludeRuleList, type)
	self:OpenInBrowserModTrades(modTrade)
end

function TradeGeneratorClass:ParserObjectToMap(objectToMap, excludeRuleList, type)
	if launch.devMode then		
		self.itemMapper = new("TradeBaseMapper", "Data/TradeMapper/Items")
		self.gemMapper = new("TradeBaseMapper", "Data/TradeMapper/Gems")
	end

	if excludeRuleList == nil then
		excludeRuleList = {SOCKETSLINKS=true, SOCKETSSLOTS=true}
	end

	type = type or "items"
	local mapper = type == "gems" and self.gemMapper or self.itemMapper

	return mapper:Execute(objectToMap, excludeRuleList)
end

function TradeGeneratorClass:OpenInBrowserModTrades(modTrade)
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
			if index == 1 or not mod.enabled then goto continue end -- Skip the first name, as it is the name of the item

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
			if index == 1 or not mod.enabled then goto continue end -- Skip the first name, as it is the name of the item

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
			if index == 1 or not mod.enabled then goto continue end -- Skip the first name, as it is the name of the item

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
			if index == 1 or not stat.enabled then goto continue end -- Skip the first stat, as it is the name of the item

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
				if not stat.enabled then goto continue2 end
				t_insert(aStats, {
					id = stat.tradeId,
					value = stat.values and #stat.values> 0 and {
						min = #stat.values > 0 and stat.values[1] or nil,
						max = #stat.values > 1 and stat.values[2] or nil,
						option = stat.option or nil
					} or nil
				})
				::continue2::
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

function TradeGeneratorClass:GeneratePopupItemSettings(objectToMap, excludeRuleList, type)
	-- generate all trade items
	local modTrade = self:ParserObjectToMap(objectToMap, {}, type)
	local title = type == "gems" and "Gem trade rules" or "Item trade rules"

	local controls = {}

	-- TODO: Enabled scroll if height is lower than the screen
	local currentY = 0
	local popupWidth = 600
	local pxPerLine = 26
	local posXGeneral = 8 + 82
	local anchor = {"TOPLEFT", nil, "TOPLEFT"}

	local function formatMaxString(str)
		local maxLen = 50
		if #str > maxLen then
			return str:sub(1, maxLen - 3) .. "..."
		end
		return str
	end
	local function nextRow(heightModifier)
		heightModifier = heightModifier or 1
		currentY = currentY + heightModifier * pxPerLine
	end
	local function drawSectionHeader(id, title)
		local headerBGColor ={ .6, .6, .6}
		controls["section-"..id .. "-bg"] = new("RectangleOutlineControl", { "TOPLEFT", nil, "TOPLEFT" }, 8, currentY, popupWidth - 17, 26, headerBGColor, 1)
		nextRow(.2)
		controls["section-"..id .. "-label"] = new("LabelControl", { "TOPLEFT", nil, "TOPLEFT" }, popupWidth / 2 - 60, currentY, 0, 16, "^7" .. title)
		nextRow(1)
	end

	nextRow(1)

	local modName = modTrade.mods['NameFilter']
	if #modName > 1 then
		drawSectionHeader("NameFilter", modName[1].display)
		for index, mod in ipairs(modName) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item
			
			controls["name_check_" .. index] = new("CheckBoxControl", anchor, posXGeneral, currentY, 18, formatMaxString(mod.displayName), function(state)			
				mod.enabled = state
			end, nil, mod.enabled)
			controls["name_value_" .. index] = new("LabelControl", {"TOPLEFT", controls["name_check_" .. index], "TOPRIGHT"}, 8, 0, 0, 16, formatMaxString(mod.value))
			nextRow(1)
			::continue::
		end
	end

	local modMisc = modTrade.mods['MiscFilter']
	if #modMisc > 1 then
		drawSectionHeader("ModMisc", modMisc[1].display)
		for index, mod in ipairs(modMisc) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item
			
			controls["modmisc_check_" .. index] = new("CheckBoxControl", anchor, posXGeneral, currentY, 18, formatMaxString(mod.displayName), function(state)			
				mod.enabled = state
			end, nil, mod.enabled)
			
			if mod.type == "quality" or mod.type == "gem_level" then
				-- first max control
				controls["modmisc_value_max" .. index] = new("EditControl", { "TOPRIGHT", nil , "TOPRIGHT" }, -8, currentY, 80, 20, mod.value.max or nil, nil, "%D", 3, function(value)
					mod.value.max = tonumber(value) or nil
				end)

				-- then min control
				controls["modmisc_value_min" .. index] = new("EditControl", { "TOPRIGHT", controls["modmisc_value_max" .. index], "TOPRIGHT" }, -84, 0, 80, 20, mod.value.min, nil, "%D", 3, function(value)
					mod.value.min = tonumber(value) or nil
				end)
			end
			nextRow(1)
			::continue::
		end
	end

	local modSocket = modTrade.mods['SocketFilter']
	if #modSocket > 1 then
		drawSectionHeader("ModSocket", modSocket[1].display)
		for index, mod in ipairs(modSocket) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item
			
			controls["modsocket_check_" .. index] = new("CheckBoxControl", anchor, posXGeneral, currentY, 18, formatMaxString(mod.displayName), function(state)			
				mod.enabled = state
			end, nil, mod.enabled)

			if mod.type == "links" then
				-- first max control
				controls["modsocket_value_max" .. index] = new("EditControl", { "TOPRIGHT", nil , "TOPRIGHT" }, -8, currentY, 80, 20, mod.value.max or nil, nil, "%D", 3, function(value)
					mod.value.max = tonumber(value) or nil
				end)

				-- then min control
				controls["modsocket_value_min" .. index] = new("EditControl", { "TOPRIGHT", controls["modsocket_value_max" .. index], "TOPRIGHT" }, -84, 0, 80, 20, mod.value.min, nil, "%D", 3, function(value)
					mod.value.min = tonumber(value) or nil
				end)
			elseif mod.type == "sockets" then
				-- first B control
				controls["modsocket_value_b" .. index] = new("EditControl", { "TOPRIGHT", nil , "TOPRIGHT" }, -8, currentY, 80, 20, mod.value.b or nil, "B", "%D", 3, function(value)
					mod.value.b = tonumber(value) or nil
				end)

				-- then G control
				controls["modsocket_value_g" .. index] = new("EditControl", { "TOPRIGHT", controls["modsocket_value_b" .. index], "TOPRIGHT" }, -84, 0, 80, 20, mod.value.g or nil, "G", "%D", 3, function(value)
					mod.value.g = tonumber(value) or nil
				end)

				-- then R control
				controls["modsocket_value_r" .. index] = new("EditControl", { "TOPRIGHT", controls["modsocket_value_g" .. index], "TOPRIGHT" }, -84, 0, 80, 20, mod.value.r or nil, "R", "%D", 3, function(value)
					mod.value.r = tonumber(value) or nil
				end)
			end

			nextRow(1)
			::continue::
		end
	end

	local modStats = modTrade.mods['StatsFilter']
	if #modStats > 1 then
		drawSectionHeader("ModStats", modStats[1].display)
		for index, mod in ipairs(modStats) do
			if index == 1 then goto continue end -- Skip the first name, as it is the name of the item
			
			controls["modstats_check_" .. index] = new("CheckBoxControl", anchor, posXGeneral, currentY, 18, formatMaxString(mod.displayName), function(state)			
				mod.enabled = state
			end, nil, mod.enabled)
			controls["modstats_value_" .. index] = new("LabelControl", {"TOPLEFT", controls["modstats_check_" .. index], "TOPRIGHT"}, 8, 0, 0, 16, formatMaxString(mod.displayValue), mod.displayValue)
			controls["modstats_value_" .. index].tooltipFunc = function(tooltip)
				tooltip:Clear()
				tooltip:AddLine(16, mod.displayValue)
				tooltip:AddSeparator(10)
				tooltip:AddLine(16, "^8TradeModId: ^7" .. mod.tradeId)
			end
			
			if not mod.option and mod.values and #mod.values > 0 then
				-- first max control
				controls["modstats_value_max" .. index] = new("EditControl", { "TOPRIGHT", nil , "TOPRIGHT" }, -8, currentY, 80, 20, #mod.values>1 and mod.values[2] or nil, nil, "%D", 3, function(value)
					mod.values[2] = tonumber(value) or nil
				end)

				-- then min control
				controls["modstats_value_min" .. index] = new("EditControl", { "TOPRIGHT", controls["modstats_value_max" .. index], "TOPRIGHT" }, -84, 0, 80, 20, mod.values[1], nil, "%D", 3, function(value)
					mod.values[1] = tonumber(value) or nil
				end)
			end

			nextRow(1)
			::continue::
		end
	end

	local modStatsCounts = modTrade.mods['StatsFilterCounts']
	if #modStatsCounts > 1 then
		for index, orGroup in ipairs(modStatsCounts) do
			if index == 1 then goto continue end -- Skip the first stat, as it is the name of the item
			drawSectionHeader("ModStats"..index, modStatsCounts[1].display .. " " .. index - 1)		
			
			for indexTwo, mod in ipairs(orGroup.values) do
				local indexName = index .. "_" .. indexTwo
				controls["modstatscount_check_" .. indexName] = new("CheckBoxControl", anchor, posXGeneral, currentY, 18, formatMaxString(mod.displayName), function(state)			
					mod.enabled = state
				end, nil, mod.enabled)
				controls["modstatscount_value_" .. indexName] = new("LabelControl", {"TOPLEFT", controls["modstatscount_check_" .. indexName], "TOPRIGHT"}, 8, 0, 0, 16, formatMaxString(mod.displayValue), mod.displayValue)
				controls["modstatscount_value_" .. indexName].tooltipFunc = function(tooltip)
					tooltip:Clear()
					tooltip:AddLine(16, mod.displayValue)
					tooltip:AddSeparator(10)
					tooltip:AddLine(16, "^8TradeModId: ^7" .. mod.tradeId)
				end
				
				if mod.values and #mod.values > 0 then
					-- first max control
					controls["modstatscount_value_max" .. indexName] = new("EditControl", { "TOPRIGHT", nil , "TOPRIGHT" }, -8, currentY, 80, 20, #mod.values>1 and mod.values[2] or nil, nil, "%D", 3, function(value)
						mod.values[2] = tonumber(value) or nil
					end)

					-- then min control
					controls["modstatscount_value_min" .. indexName] = new("EditControl", { "TOPRIGHT", controls["modstatscount_value_max" .. indexName], "TOPRIGHT" }, -84, 0, 80, 20, mod.values[1], nil, "%D", 3, function(value)
						mod.values[1] = tonumber(value) or nil
					end)
				end

				nextRow(1)
			end

			::continue::
		end
	end

	nextRow(0.5)
	controls.generate = new("ButtonControl", {"TOPLEFT", nil, "TOPLEFT"} , (popupWidth / 2) - 120 - (6/2),currentY, 120, 20, "Open Trade Link", function()
		self:OpenInBrowserModTrades(modTrade)
		main:ClosePopup()
	end)
	
	controls.close = new("ButtonControl", {"TOPLEFT", controls.generate, "TOPRIGHT"}, 6, 0, 120, 20, "Cancel", function()
		main:ClosePopup()
	end)
	
	nextRow(1)
	main:OpenPopup(popupWidth, currentY, title, controls, nil, nil, "close", nil, nil)
end