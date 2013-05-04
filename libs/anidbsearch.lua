local db = require'db'

local scores = {
	main = 1,
	syn = .8,
	short = .5,
	official = 1,
}

local THRESHOLD = 100

local function tokenize(text)
	local tokens = {}
	local unique = {}
	for token in text:gmatch('[^%s]+') do
		if #token and not unique[token] then
			tokens[#tokens+1] = token
			unique[token] = true
		end
	end
	return tokens
end

local insert = function(tbl, aid, weight)
	weight = math.floor(weight)
	if(weight < THRESHOLD) then return end

	local query = "select show_title(%d, 'en', 'anidb')"
	local title = _DB:execute(query:format(aid)):fetch()

	local data = tbl[aid]
	if(data and data[2] < weight) then
		data[2] = weight
	elseif(not data) then
		tbl[aid] = {title, weight}
	end 
end

local doSearch = function(pattern)
	local matches = {}
	local search = pattern:lower():gsub('([-?]+)', '%%%1'):gsub('\'', '`')
	local tokens = tokenize(search)

	local query = "select show_id, type from ningyou_titles where keywords @@ to_tsquery('%s')"
	local res, err = _DB:execute(query:format(table.concat(tokens, ":* & ") .. ":*"))
	if err then return print(err) end
	for show_id, show_type in db:results(res) do
		insert(matches, show_id, 1e3 * scores[show_type])
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
