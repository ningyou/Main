local ob = require'ob'
local json = require'json'
local user = require'user'
local redis = require'redis'
local bunraku = require'bunraku'
local listlib = require'list'

local content = ob.Get'Content'
local sites = dofile'config/sites.lua'

local safeFormat = function(format, ...)
	if select('#', ...) > 0 then
		local success, message = pcall(string.format, format, ...)
		if success then
			return message
		end
	else
		return format
	end
end

local function err(...)
	local message = safeFormat(...)
	content:write(json.encode({ error = message }))
end

local function check_token(token)
	local token_info = _DB:find_one('ningyou.api', { token = token })
	if token_info then
		return token_info
	else
		return nil, 'Wrong token.'
	end
end

local function find_show(ids, id)
	local id = tonumber(id)
	for i,v in next, ids do
		if tonumber(v.id) == id then
			return v
		end
	end
end

local methods = {
	[1] = {
		requesttoken = function(token, username, password, app)
			if not app then return err'Application name not defined', true end
			if not username or not password then return err'Username or Password not defined', true end
			local username = user:Login(username, password)
			if not username then return err'Username or Password is wrong', true end

			local token = string.SHA256(username..os.time())
			local success, fail = _DB:insert('ningyou.api', {
				app = app,
				token = token,
				user = username,
			})
			if not success then return err'Unable to store token in database, try again later.', true end

			content:write(json.encode({ token = token }))
		end,
		getlists = function(token, user)
			if not token then return err'No token defined', true end
			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local username = user or token['user']
			local list_info = _DB:query('ningyou.lists', { user = username }, nil, nil, { name = 1, type = 1, _id = 0 })
			if not list_info then return err'No lists found', true end

			local out = {}
			for info in list_info:results() do
				table.insert(out, { name = info.name, type = info.type })
			end
			table.sort(out, function(a,b) return a.name:lower() < b.name:lower() end)

			content:write(json.encode(out))
		end,
		updateshow = function(token, list, id, episode, status)
			if not token then return err'No token defined', true end
			if not list then return err'No list defined', true end
			if not id then return err'No show id defined', true end
			if not episode then return err'No episode number defined', true end

			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local username = token['user']
			local client = redis.connect()
			local list_lower = list:lower()
			local episode = tonumber(episode)
			local today = os.date('%Y-%m-%d')

			local list_info = _DB:find_one("ningyou.lists", { user = username, name_lower = list_lower, ['ids.id'] = id })
			if not list_info then return err('Unable to find id %d in list %s', id, list), true end

			local key = sites[list_info.type]..":"..id
			local total
			if client:hexists(key, "enddate") then
				total = client:hget(key, "episodecount") or "N/A"
			elseif client:hexists(key, "status") then
				local status = client:hget(key, "status")
				if status ~= "Continuing" then
					total = client:hget(key, "episodecount") or "N/A"
				end
			end

			local status = status
			local statuschange
			if total and episode >= tonumber(total) then
				episode = episodes
				status = "Completed"
			end

			local success, err = listlib:updateshow(list, id, 'episodes', episode)
			if not success then return err('Unable to add id %d to list %s, try again later', id, list), true end

			if status then
				success, err = listlib:updateshow(list, id, 'status', status)
			end
			if not success then return err('Unable to change status of id %d in list %s, try again later', id, list), true end

			client:quit()
			content:write(json.encode({ result = "success", id = id, episode = episode, status = status }))
		end,
		addshow = function(token, list, id, status, episode)
			if not token then return err'No token defined', true end
			if not list then return err'No list defined', true end
			if not id then return err'No show id defined', true end
			local episode = episode or 0
			local status = status or 'Watching'

			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local username = token['user']
			local list_lower = list:lower()

			local list_info = _DB:find_one('ningyou.lists', { user = username, name_lower = list_lower, ['ids.id'] = id })
			if list_info then return err('Show with id %d in list %s already exists, ignoring', id, list), true end

			local success, err = listlib:addshow(list, id, episode, status)
			if not success then return err('Unable to add id %d to list %s, try again later', id, list), true end

			content:write(json.encode({ result = 'success', id = id, episode = episode, status = status }))
		end,
		getshow = function(token, list, id)
			if not token then return err'No token defined', true end
			if not list then return err'No list defined', true end
			if not id then return err'No show id defined', true end

			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local username = token['user']
			local list_lower = list:lower()

			local list_info = _DB:find_one('ningyou.lists', { user = username, name_lower = list_lower, ['ids.id'] = id })
			if not list_info then return err('Unable to find id %d in list %s', id, list), true end

			local show_info = find_show(list_info['ids'], id)

			local client = redis.connect()
			local today = os.date('%Y-%m-%d')

			local key = sites[list_info.type]..":"..id
			local total
			if client:hexists(key, "enddate") then
				total = client:hget(key, "episodecount") or "N/A"
			elseif client:hexists(key, "status") then
				local status = client:hget(key, "status")
				if status ~= "Continuing" then
					total = client:hget(key, "episodecount") or "N/A"
				end
			end
			client:quit()

			show_info.total = total

			content:write(json.encode(show_info))
		end,
		getlist = function(token, list, username)
			if not token then return err'No token defined', true end
			if not list then return err'No list defined', true end

			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local check_user = username or token['user']
			local username = user:Exists(check_user)
			if not username then return err('Username %s not found.', check_user), true end

			local list_lower = list:lower()
			local list_info = _DB:find_one("ningyou.lists", { user = username, name_lower = list })
			if not list_info then return err('Unable to find list %s under user %s', list, username), true end

			local not_in_cache = {}
			local lists = {}
			table.insert(not_in_cache, sites[list_info.type])

			local cache = redis.connect('127.0.0.1', 6379)
			if not list_info.ids then return nil, true end

			for _, info in next, list_info.ids do
				local key = sites[list_info.type]..":"..info.id
				if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
						table.insert(not_in_cache, info.id)
				end
				local today = os.date('%Y-%m-%d')
				if not lists[info.status] then lists[info.status] = {} end
				info.title = find_title(tonumber(info.id), sites[list_info.type])
				if list_info.type == "tv" then
				info.type = "TV Series"
				else
					info.type = cache:hget(key, "type") or "N/A"
				end
				if cache:hexists(key, "enddate") then
					info.total = cache:hget(key, "episodecount") or "N/A"
					info.aired = cache:hget(key, "enddate") < today
				elseif cache:hexists(key, "status") then
					local status = cache:hget(key, "status")
					if status ~= "Continuing" then
						info.total = cache:hget(key, "episodecount") or "N/A"
						info.aired = true
					end
				end
				if cache:hexists(key, "startdate") and cache:hget(key, "startdate"):match"%d+-%d+-%d+" then
					info.notyet = cache:hget(key, "startdate") > today
					info.startdate = cache:hget(key, "startdate")
				elseif cache:hexists(key, "status") then
					local status = cache:hget(key, "status")
					if status == "Continuing" then
						info.notyet = false
					end
				else
					info.notyet = true
				end
				table.insert(lists[info.status], info)
			end
			cache:quit()
			for _, ids in next, lists do
				table.sort(ids, function(a,b) return a.title:lower() < b.title:lower() end)
			end
			if not_in_cache[2] then
				local send = table.concat(not_in_cache, ",")
				bunraku:Send(send)
			end
			content:write(json.encode(lists))
		end,
	}
}

return {
	index = function(api, version, method, ...)
		local version = tonumber(_POST['version'] or version)
		local token = _POST['token'] or _GET['token']
		local method = _POST['method'] or method

		local params
		if #{...} > 1 then params = {...} else params = ... end
		local params = _POST['params'] or params

		if not methods[version][method] then return err'Method not found', true end

		if type(params) == 'table' then
			methods[version][method](token, unpack(params))
		else
			methods[version][method](token, params)
		end

		return nil, true
	end,
}
