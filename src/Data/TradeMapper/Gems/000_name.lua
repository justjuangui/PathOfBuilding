return {
	id = "NAME",
	name = "Name",
	run = function (gem, modTrade, parseLineTrade)
		if gem.nameSpec then
			local gemName = gem.nameSpec
			-- validate variant ID
			if gem.gemData and gem.gemData.variantId:match("Alt[XY]") then
				local discriminator = ""
				local option = gem.gemData.variantId:gsub("Alt[XY]", function(k, val)
					if k == "AltX" then
						discriminator = "alt_x"
					elseif k == "AltY" then
						discriminator = "alt_y"
					end
					return ""	
				end)

				local fmtOption = ""
				for wrd in option:gmatch("%u%U*") do 
					fmtOption = fmtOption .. wrd ..  " "
				end

				fmtOption = fmtOption:match( "^%s*(.-)%s*$" )

				modTrade:NewMod("NameFilter", "type", {
					discriminator=discriminator,
					option=fmtOption,
				})	
			else
				if gem.supportEffect and gem.skillId:match("Support") then
					gemName = gemName .. " Support"
				end
				modTrade:AddMod({name="NameFilter", type="type", value=gemName, displayName="Name", enabled=true})
			end
		end	
	end
}