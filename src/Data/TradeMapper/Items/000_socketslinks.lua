return {
	id = "SOCKETSLINKS",
	name = "Sockets Links",
	run = function (item, modTrade, parseLineTrade)
		if item.sockets and #item.sockets > 0 then
			local links = {}
			for _, socket in ipairs(item.sockets) do
				local socketColor = socket.color:lower()
			
				if not links[socket.group] then 
					links[socket.group] = {min = 0}
				end
				links[socket.group].min = links[socket.group].min + 1
				links[socket.group][socketColor] = (links[socket.group][socketColor] or 0) + 1 
			end
			
			local maxLinks = nil
			for _, link in pairs(links) do
				if not maxLinks or link.min > maxLinks.min then
					maxLinks = link
				end
			end
			if maxLinks then
				modTrade:NewMod("SocketFilter", "links", maxLinks)
			end
		end
	end
}