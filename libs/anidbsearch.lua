local scores = {
	main = 1,
	syn = .8,
	short = .5,
	official = 1,
}

local delims = " \t\r\n"
local THRESHOLD = 100

local function tokenize(text)
	local tokens = { ["$and"] = {}}
	local unique = {}
	for token in text:gmatch("[^%s]+") do
		if #token and not unique[token] and token:len() > 1 then
			table.insert(tokens["$and"], { _keywords = token })
			unique[token] = true
		end
	end
	return tokens
end

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
		if y then
			return insert(tbl, aid, 1e3 * (1 + y - x) / #title *  scores[type])
		end
	end
end

local doSearch = function(pattern)
	local pattern = pattern:gsub("[^%w_0-9]+", " ")
	local matches = {}
	local search = pattern:lower():gsub('([-?]+)', '%%%1'):gsub("'", '`')
	local tokens = tokenize(search)

	local result = _DB:query("ningyou.anidbtitles", tokens)
	for r in result:results() do
		insert(matches, r.anidb_id, 1e3 * scores[r.type])
	end

	local output = {}
	for k,v in next, matches do
		table.insert(output, {id = k, title = v[1], weight = v[2]})
	end

	table.sort(output, function(a,b) return a.weight > b.weight end)
	
	return output
end

return {
	lookup = doSearch,
}

