local zlib = require'zlib'

local handleFormat = function(data)
	local id1, id2 =  data:byte(1, 2)
	if(id1 == 0x1f and id2 == 0x8b) then
		return (zlib.inflate()(data))
	else
		return data
	end
end

local importantFields = {
	series_title = true,
	series_type = true,
	series_episodes = true,

	my_watched_episodes = true,
	my_score = true,
	my_rated = true,

	my_start_date = true,
	my_finish_date = true,
}

local parse = function(self, data)
	local list = {}
	local entry

	local handleFields = function(field, var)
		if(importantFields[field]) then
			entry[field:gsub('^%w+_', '')] = tonumber(var) or var
		end
	end

	for anime in data:gmatch('<anime>(.-)</anime>') do
		entry = {}

		anime = anime:gsub('<!%[CDATA%[(.-)%]%]>', '%1')
		anime:gsub('<([a-zA-Z0-9_]+)>(.-)</%1>', handleFields)

		table.insert(list, entry)
	end

	return list
end
