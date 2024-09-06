return {
	id = "NAME",
	name = "Name",
	run = function (item, modTrade, parseLineTrade)
		local color = colorCodes[item.rarity:upper()]  or colorCodes.NORMAL
		if item.baseName then
			modTrade:AddMod({name="NameFilter", type="type", value=item.baseName, displayName= "Base", displayValue= color .. item.baseName, enabled=true})
		end	
		if item.rarity == 'UNIQUE' and item.title then
			modTrade:AddMod({name="NameFilter", type="name", value=item.title, displayName=  "Name", displayValue= color.. item.title, enabled=true})
		end
	end
}