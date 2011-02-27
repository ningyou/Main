local lpeg = require'lpeg'

local split = function(s, sep)
	sep = lpeg.P(sep)
	local elem = lpeg.C((1 - sep)^0)
	local p = lpeg.Ct(elem * (sep * elem)^0)

	return lpeg.match(p, s)
end

local handleTVRage = function(str)
	local data = {}

	local tmp = split(str:gsub("\n", "@"), "@")
	for i = 1, #tmp, 2 do
		local k, v = tmp[i], tmp[i+1]
		data[k] = v
	end

	return data
end

return function(self, search)
	local serie, status = http:get("http://services.tvrage.com/tools/quickinfo.php?show=" .. search:gsub("%s", "+"))
	if(serie and status == 200) then
		if(serie:sub(1, 15) ~= "No Show Results") then
			return handleTVRage(serie:gsub("<pre>", ""))
		end
	end
end
