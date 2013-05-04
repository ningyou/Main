local _M = {}
local sessions = require'sessions'
local mp = require'cmsgpack'
local bunraku = require'bunraku'
local key = 'cache:%s:%s'
local sites = dofile'config/sites.lua'
local date = os.date
local db = require'db'
local mp = require'cmsgpack'

local history = function(action, htype, list, id, value)
	_CLIENT:command('rpush', 'history:'..sessions.user_id, mp.pack({
		time = os.time(),
		action = action,
		type = htype,
		list = list,
		id = id,
		value = value,
	}))
end

-- TODO: Add language support.
function _M:show_title(id, site, lang)
if site == 'tvdb' then
	local key = ('%s:%d'):format(site, id)
	local title = _CLIENT:command('hget', key, 'title')
	if title == 'table' then return end

	return title
else
	local db_name = ('ningyou.%stitles'):format(site)
	local site_id = ('%s_id'):format(site)
	local title =
	_DB:find_one(db_name, { [site_id] = id, type = 'official', lang = 'en' }, "title")
	or
	_DB:find_one(db_name, { [site_id] = id, type = 'main' }, "title")
	if not title then return nil, ("Unable to find title of %s id: %d"):format(site, id) end

	if type(title) ~= "string" then return end
	return title
end
end

function _M:addshow(user_id, list_id, show_id, episode, status, rating)
	local check = "select 1 from ningyou_list_data where list_id = %d and show_id = %d limit 1"
	if _DB:execute(check:format(list_id, show_id)):numrows() == 1 then return end

	local query = "insert into ningyou_list_data (list_id, status_id, show_id, episodes) values (%d, %d, %d, %d) where list_id = %d"
	local success, err = _DB:execute(query:format(list_id, status_id, show_id, episodes))
	if not success then return nil, err end

	_CLIENT:command('del', key:format(user_id, list_id))
	--history('add', 'show', list, id, status)

	return true
	end

function _M:updateshow(user_id, list_id, show_id, episodes, status_id)
	local check = "select 1 from ningyou_list_data where list_id = %d and show_id = %d limit 1"
	if _DB:execute(check:format(list_id, show_id)):numrows() == 0 then return end

	local query = "update ningyou_list_data set episodes = %d, status_id = %d where list_id = %d and show_id = %d"
	local success, err = _DB:execute(query:format(episodes, status_id, list_id, show_id))
	if not success then return print(err) end

	_CLIENT:command('del', key:format(user_id, list_id))
	--history('update', attr, list, id, value)

	return true
end

function _M:removeshow(user_id, list_id, show_id)
	local check = "select 1 from ningyou_list_data where list_id = %d and show_id = %d limit 1"
	if _DB:execute(check:format(list_id, show_id)):numrows() == 0 then return end

	local query = "delete from ningyou_list_data where list_id = %d and show_id = %d"
	local success, err = _DB:execute(query:format(list_id, show_id))
	if not success then return nil, err end

	_CLIENT:command('del', key:format(user_id, list_id))
	--history('remove', 'show', list, id)

	return true
end

function _M:addlist(list, list_type)
	local user_id = sessions.user_id
	if db:get_list_info(user_id, list) then return nil, ('List "%s" already exists.'):format(list) end
	local query = "insert into ningyou_lists (user_id, name, type_id) values (%d, '%s', %d)"

	local success, err = _DB:execute(query:format(user_id, list, tonumber(list_type)))
	if not success then return nil, err end
	return true
end

function _M:removelist(list)
	local list_id = tonumber(list) or db:get_list_info(sessions.user_id, list)
	if not list_id then return end

	local query = "delete from ningyou_lists where id = %d"
	local success, err = _DB:execute(query:format(list_id))
	if not success then return nil, err end

	return true
end

function _M:getlist(user_id, list) 
	local list_id, list_name, list_site, list_url = db:get_list_info(user_id, list)
	local cache_key = ('cache:%s:%s'):format(user_id, list_id)
	local cache = _CLIENT:command('get', cache_key)

	-- If cache exists, return it.
	if type(cache) ~= 'table' then 
		return mp.unpack(cache), list_name, list_site, list_id, list_url
	end 

	local status = db:unnest('status', list_id)

	local lists = {}
	local not_in_cache = {}
	not_in_cache[1] = list_site

	for i = 1, #status do
		lists[i] = db:get_list(list_id, i)
		for _, info in next, lists[i] do
			local key = ('%s:%d'):format(list_site, info.id)
			local ttl = _CLIENT:command('ttl', key)

			local show_info = _CLIENT:command('hgetall', key)
			-- Arrange the return as key = value
			for i = 1, #show_info, 2 do
				show_info[show_info[i]] = show_info[i+1]
				show_info[i] = nil
				show_info[i+1] = nil
			end

			if not (_CLIENT:command('exists', key) == 1 and (ttl > 86400 or ttl == -1)) then
				not_in_cache[#not_in_cache+1] = info.id
			end

			local today = date('%Y-%m-%d')

			if list_site == 'tvdb' then
				info.title = show_info.title
				info.type = 'TV Series'
			else
				info.type = show_info.type or 'N/A'
			end

			if show_info.enddate then
				info.total = show_info.episodecount or 'N/A'
				info.aired = show_info.enddate < today
			elseif show_info.status and show_info.status ~= 'Continuing' then
				info.total = show_info.episodecount or 'N/A'
				info.aired = true
			end

			if show_info.startdate and show_info.startdate:match'%d+-%d+-%d+' then
				info.notyet = show_info.startdate > today
				info.startdate = show_info.startdate
			elseif info.startdate then
				info.notyet = true
				info.startdate = show_info.startdate
			end
		end
	end

	if not_in_cache[2] then
		bunraku:Send(table.concat(not_in_cache, ','))
	else
		--_CLIENT:command('setex', cache_key, 7200, mp.pack(lists))
	end

	return lists, list_name, list_site, list_id, list_url
end

return _M
