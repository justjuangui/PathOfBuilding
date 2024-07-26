return {
	id = "NAME",
	name = "Name",
	run = function (item, modTrade, parseLineTrade)
		if item.baseName then
			modTrade:NewMod("NameFilter", "type", item.baseName)
		end	
		if item.rarity == 'UNIQUE' and item.title then
			modTrade:NewMod("NameFilter", "name", item.title)
		end
	end
}