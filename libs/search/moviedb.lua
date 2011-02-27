local json = require"json"

return function(self, search)
	-- IMDB id search.
	local movie, status
	if(search:match("^tt(%d+)")) then
		movie, status = http:get("http://api.themoviedb.org/2.1/Movie.imdbLookup/en/json/" .. self.apikey"moviedb" .. "/" .. search)
	else
		movie, status = http:get("http://api.themoviedb.org/2.1/Movie.search/en/json/" .. self.apikey"moviedb" .. "/" .. search:gsub("%s", "+"))
	end

	if(movie and status == 200) then
		return json.decode(movie)
	end
end
