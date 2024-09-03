return {
	id = "NAME",
	name = "Name",
	run = function (item, modTrade, parseLineTrade)
		if item.baseName then
			modTrade:AddMod({name="NameFilter", type="type", value=item.baseName, displayName="Base", enabled=true})
		end	
		if item.rarity == 'UNIQUE' and item.title then
			modTrade:AddMod({name="NameFilter", type="name", value=item.title, displayName="Name", enabled=true})
		end
	end
}