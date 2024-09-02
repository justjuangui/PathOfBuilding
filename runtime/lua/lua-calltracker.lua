local module = {}
local getTime = os.clock


local ignoreFunctions = {
	"for generator",
	"pairs",
	"ipairs",
	"next",
	"select",
	"gsub",
	"t_insert"
}
local function OnHook(hookType)
	local information  = debug.getinfo(2, "nS")

	if hookType == "call" then
		local src = information.short_src or "[C]"
		if string.sub(src, #src - 3, #src) == ".lua" then
			src = string.sub(src, 1, #src - 4)
		end
		local name = information.name or "unknown"
		local ignore = false
		for _, v in ipairs(ignoreFunctions) do
			if name:match(v) then
				ignore = true
				break
			end
		end
		module.stack[#module.stack + 1] = {name = name, ignore = ignore, startTime = getTime(), src = src, endTime = 0, line = information.linedefined or 0}
	elseif hookType == "return" then
		local endTime = getTime()
		local top = module.stack[#module.stack]
		top.endTime = endTime
		local duration = top.endTime - top.startTime
		table.remove(module.stack, #module.stack)

		if top.ignore == false then
			module.fileWriter:write(string.format("%-50s :: %-50s :: %-5i :: %-10f %-10f %-10f\n", top.src, top.name, top.line, duration, top.startTime, top.endTime))
		end
	end
end

local function Stop()
	debug.sethook()
	if module.fileWriter then

		module.fileWriter:write("\nDone\n")
		module.fileWriter:close()
		module.fileWriter = nil
	end
end

local function Start(name, filename)
	module.filename = filename
	module.fileWriter = io.open(filename, "w+")
	module.stack = {}
	module.stack[1] = {name = name, src="Origin", ignore = false, startTime = getTime(),  endTime = 0, line = 0}
	module.fileWriter:write(string.format("%-50s :: %-50s :: %-5s :: %-10s %-10s %-10s\n", "File", "Function", "Line", "Duration", "Start", "End"))
	debug.sethook(OnHook, "cr", 0)
end

return {
	Start = Start,
	Stop = Stop
}