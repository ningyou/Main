require"json"
require"lpeg"

local http = require"http"

-- Subject for change. Store these in mongo?
local moviedb_apikey = io.open"moviedb_apikey":read"*all":gsub("\n$", "")

local _M = {}

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

function _M:moviedb(search)
	-- IMDB id search.
	if search:match("tt(%d+)") then
		local movie, status = http:get("http://api.themoviedb.org/2.1/Movie.imdbLookup/en/json/" .. moviedb_apikey .. "/" .. search)
		if movie and status == 200 then
			movie = json.decode(movie)
			return movie
		end
	else
		search = search:gsub("%s", "+")
		local movie, status = http:get("http://api.themoviedb.org/2.1/Movie.search/en/json/" .. moviedb_apikey .. "/" .. search)
		if movie and status == 200 then
			movie = json.decode(movie)
			return movie
		end
	end
end

function _M:tvrage(search)
	search = search:gsub("%s", "+")
	local serie, status = http:get("http://services.tvrage.com/tools/quickinfo.php?show=" .. search)
	if serie and status == 200 then
		if serie:sub(1, 15) == "No Show Results" then
			return
		else
			serie = serie:gsub("<pre>", "")
			local data = handleTVRage(serie)

			if data then return data else return end
		end
	end
end
return _M
