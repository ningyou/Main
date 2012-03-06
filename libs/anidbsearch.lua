local scores = {
	main = 1,
	syn = .8,
	short = .5,
	official = 1,
}

local THRESHOLD = 100
local insert = function(tbl, aid, weight)
	weight = math.floor(weight)
	if(weight < THRESHOLD) then return end

	local title = _DB:find_one("ningyou.anidbtitles", { anidb_id = aid, type = "official", lang = "en" }, { title = 1 }) or _DB:find_one("ningyou.anidbtitles", { anidb_id = aid, type = "main" }, { title = 1 })
	title = title.title

	local data = tbl[aid]
	if(data and data[2] < weight) then
		data[2] = weight
	elseif(not data) then
		tbl[aid] = {title, weight}
	end
end

local compare = function(tbl, aid, type, pattern, title)
	title = title:lower()

	if(pattern == title) then
		return insert(tbl, aid, 1e3 * scores[type])
	else
		local x, y = title:find(pattern)
		if(y) then
			return insert(tbl, aid, 1e3 * (1 + y - x) / #title *  scores[type])
		end
	end
end

local doSearch = function(pattern)
	local matches = {}
	local search = pattern:lower():gsub('([-?]+)', '%%%1'):gsub("'", '`')
	-- Search, lol!
	for _, type in next, { 'main', 'syn', 'short', 'official' } do
		local query = _DB:query("ningyou.anidbtitles", { type = type })
		for r in query:results() do
			compare(matches, r.anidb_id, r.type, search, r.title)
		end
	end
	
	local output = {}
	for k,v in next, matches do
		table.insert(output, {aid = k, title = v[1], weight = v[2]})
	end

	table.sort(output, function(a,b) return a.weight > b.weight end)
	
	return output
end

return {
	lookup = doSearch,
}

