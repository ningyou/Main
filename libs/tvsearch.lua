local http = require'socket.http'
local ltn12 = require'ltn12'
local lom = require'lxp.lom'
local xpath = require'xpath'
local redis = require'redis'
local json = require'json'
local url = require'socket.url'

local function add_cache(pattern, info)
	local client = redis.connect()
	local key = 'tvsearch:'..pattern:lower()

	client:set(key, json.encode(info))
	client:quit()
end

local function check_cache(pattern)
	local client = redis.connect()
	local key = 'tvsearch:'..pattern:lower()

	if client:exists(key) then
		local data = client:get(key)
		client:quit()
		return json.decode(data)
	end
end

function http.get(u)
	local t = {}
	local r, c, h = http.request{
		url = u,
		sink = ltn12.sink.table(t),
		headers = {
			['Accept-Encoding'] = 'deflate',
		},
	}
	return table.concat(t), r, c, h
end

local doSearch = function(pattern)
	local in_cache = check_cache(pattern:gsub('%s', '_'):lower())
	if in_cache then return in_cache end

	local xml = http.get(('http://www.thetvdb.com/api/GetSeries.php?seriesname=%s'):format(url.escape(pattern)))
	local xml_tree = lom.parse(xml)
	local id = xpath.selectNodes(xml_tree, '/Data/Series/seriesid/text()')
	local title = xpath.selectNodes(xml_tree, '/Data/Series/SeriesName/text()')
	local output = {}
	for i = 1, #id do
		table.insert(output, { id = id[i], title = title[i] })
	end

	add_cache(pattern:gsub('%s', '_'):lower(), output)

	return output
end

return {
	lookup = doSearch,
}
