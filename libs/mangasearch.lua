local insert = function(tbl, id)
	local title = _DB:find_one("ningyou.mangatitles", { manga_id = id }, { title = 1 })
	title = title.title

	local data = tbl[id]
	if(not data) then
		tbl[id] = {title}
	end
end

local compare = function(tbl, id, pattern, title)
	title = title:lower()

	if(pattern == title) then
		return insert(tbl, id)
	else
		local x, y = title:find(pattern)
		if(y) then
			return insert(tbl, id)
		end
	end
end

local doSearch = function(pattern)
	local matches = {}
	local search = pattern:lower():gsub('([-?]+)', '%%%1'):gsub("'", '`')
	local query = _DB:query("ningyou.mangatitles", {})
	for r in query:results() do
		compare(matches, r.manga_id, search, r.title)
	end
	
	local output = {}
	for k,v in next, matches do
		table.insert(output, {id = k, title = v[1]})
	end
	
	return output
end

return {
	lookup = doSearch,
}

