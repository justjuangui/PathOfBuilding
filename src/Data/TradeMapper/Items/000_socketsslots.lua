return {
	id = "SOCKETSSLOTS",
	name = "Sockets slots",
	run = function (item, modTrade, parseLineTrade)
		if item.sockets and #item.sockets > 0 then
			local sockets = {}
			for _, socket in ipairs(item.sockets) do
				local socketColor = socket.color:lower()
				sockets[socketColor] = (sockets[socketColor] or 0) + 1
			end
			modTrade:AddMod({name="SocketFilter", type="sockets", value=sockets, enabled=false, displayName="Slots"})
		end
	end
}