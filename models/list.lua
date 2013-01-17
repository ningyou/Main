local _M = {}
local json = require'json'
local sessions = require'sessions'
local mp = require'cmsgpack'
local bunraku = require'bunraku'
local key = 'cache:%s:%s'
local sites = dofile'config/sites.lua'
local date = os.date

--TODO: Change to msgpack.
local history = function(action, htype, list, id, value)
	_CLIENT:command('rpush', 'history:'..sessions.username, json.encode({
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
		local r =
		_DB:find_one(db_name, { [site_id] = id, type = 'official', lang = 'en' }, { title = 1, _id = 0})
		or
		_DB:find_one(db_name, { [site_id] = id, type = 'main' }, { title = 1, _id = 0})
		if not r then return nil, ("Unable to find title of %s id: %d"):format(site, id) end

		if type(r.title) ~= "string" then return end
		return r.title
	end
end

function _M:addshow(list, id, episode, status, rating)
	local list = list:lower()
	local user = sessions.username
	if _DB:find_one('ningyou.lists', { user = user, name_lower = list, ['ids.id'] = id }) then return end

	_CLIENT:command('del', key:format(user, list))
	local success, err = _DB:update('ningyou.lists', {
		user = user,
		name_lower = list,
	}, {
		['$push'] = {
			ids = {
				id = id,
				status = status,
				episodes = episode,
				rating = rating,
			}
		}
	})

	if not success then return nil, err end

	history('add', 'show', list, id, status)

	return true
end

function _M:updateshow(list, id, attr, value)
	local list = list:lower()
	local user = sessions.username
	if not _DB:find_one('ningyou.lists', { user = user, name_lower = list, ['ids.id'] = id }) then return end

	_CLIENT:command('del', key:format(user, list))
	local success, err = _DB:update('ningyou.lists', {
		user = user,
		name_lower = list,
		['ids.id'] = id,
	}, {
		['$set'] = {
			['ids.$.'..attr] = value,
		}
	})

	if not success then return nil, err end

	history('update', attr, list, id, value)

	return true
end

function _M:removeshow(list, id)
	local list = list:lower()
	local user = sessions.username

	_CLIENT:command('del', key:format(user, list))
	local success, err = _DB:update('ningyou.lists', {
		user = user,
		name_lower = list,
		['ids.id'] = id
	}, {
		['$unset'] = {
			['ids.$'] = 1,
		}
	})
	if not success then return nil, err end

	-- Remove the null left by $unset.
	local success, err = _DB:update('ningyou.lists', {
		user = user,
		name_lower = list,
	}, {
		['$pull'] = {
			ids = mongo.NULL(),
		}
	})
	if not success then return nil, err end

	history('remove', 'show', list, id)

	return true
end

function _M:addlist(list, list_type)
	local user = sessions.username
	if _DB:find_one('ningyou.lists', { user = user, name_lower = list:lower() }) then return nil, ('List "%s" already exists.'):format(list) end

	local success, err = _DB:insert('ningyou.lists', { user = user, name = list, type = list_type, name_lower = list:lower() })
	if not success then return nil, err end
	return true
end

function _M:removelist(list)
	local list = list:lower()
	local user = sessions.username
	if not _DB:find_one('ningyou.lists', { user = user, name_lower = list }) then return end

	local success, err = _DB:remove('ningyou.lists', { user = user, name_lower = list }, true)
	if not success then return nil, err end

	return true
end

function _M:getlist(username, list)
	local list = list:lower()
	local cache_key = ('cache:%s:%s'):format(username, list)
	local cache = _CLIENT:command('get', cache_key)
	local list_type = _DB:find_one('ningyou.lists', { user = username, name_lower = list }, { type = 1, _id = 0 }).type

	-- If cache exists, return it.
	if type(cache) ~= 'table' then
		return mp.unpack(cache), list_type
	end

	local list_info = _DB:find_one('ningyou.lists', { user = username, name_lower = list })
	if not list_info or not list_info.ids then return end

	local lists = {}
	local not_in_cache = {}
	not_in_cache[1] = sites[list_info.type].name

	for i = 1, #list_info.ids do
		local info = list_info.ids[i]
		local key = ('%s:%d'):format(sites[list_info.type].name, info.id)
		local ttl = _CLIENT:command('ttl', key)

		if not (_CLIENT:command('exists', key) == 1 and (ttl > 86400 or ttl == -1)) then
			not_in_cache[#not_in_cache+1] = info.id
		end

		local show_info = _CLIENT:command('hgetall', key)
		-- Arrange the return as key = value
		for i = 1, #show_info, 2 do
			show_info[show_info[i]] = show_info[i+1]
			show_info[i] = nil
			show_info[i+1] = nil
		end

		local today = date('%Y-%m-%d')
		if not lists[info.status] then lists[info.status] = {} end
		info.title = self:show_title(tonumber(info.id), sites[list_info.type].name) or 'N/A'
		if list_info.type == 'tv' then
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
		elseif show_info.status and status == 'Continuing' then
			info.notyet = false
		else
			info.notyet = true
		end
		local index = #lists[info.status]
		lists[info.status][index+1] = info
	end

	for _, ids in next, lists do
		table.sort(ids, function(a,b) return a.title:lower() < b.title:lower() end)
	end

	if not_in_cache[2] then
		bunraku:Send(table.concat(not_in_cache, ','))
	else
		_CLIENT:command('setex', cache_key, 7200, mp.pack(lists))
	end

	return lists, list_info.type
end

return _M
