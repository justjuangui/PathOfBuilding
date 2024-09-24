return {
	id = "CATEGORY",
	name = "Category",
	run = function (item, modTrade, parseLineTrade, parseRangeOrCustom, itemFilter)
		local itemType = item.type:lower()

		if itemType == "jewel" and item.base and item.base.subType and (item.base.subType == "Abyss" or item.base.subType == "Cluster") then
			itemType = itemType .. "." .. item.base.subType:lower() 
		elseif itemType == "body armour" then
			itemType = "armour.chest"
		end
		
		for name, id in pairs(itemFilter) do
			if id:find(itemType) then
				modTrade:AddMod({name="TypeFilter", type="category", value={option=id}, displayName="Category", displayValue=name, enabled=false})
				goto done
			end
		end
		:: done ::
	end
}