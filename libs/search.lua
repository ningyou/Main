require"json"

local http = require"http"

-- Subject for change. Store these in mongo?
local moviedb_apikey = io.open"moviedb_apikey":read"*all":gsub("\n$", "")

local _M = {}

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

return _M
