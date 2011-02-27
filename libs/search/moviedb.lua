local json = require"json"

return function(self, search)
	-- IMDB id search.
	if search:match("tt(%d+)") then
		local movie, status = http:get("http://api.themoviedb.org/2.1/Movie.imdbLookup/en/json/" .. self.apikey"moviedb" .. "/" .. search)
		if movie and status == 200 then
			movie = json.decode(movie)
			return movie
		end
	else
		search = search:gsub("%s", "+")
		local movie, status = http:get("http://api.themoviedb.org/2.1/Movie.search/en/json/" .. self.apikey"moviedb" .. "/" .. search)
		if movie and status == 200 then
			movie = json.decode(movie)
			return movie
		end
	end
end
