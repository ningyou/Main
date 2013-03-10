local ob = require'ob'
local json = require'json'
local user = require'user'
local redis = require'redis'
local bunraku = require'bunraku'
local listlib = require'list'
local sessions = require'sessions'
local client = _CLIENT
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
		sessions.username = token_info.user
		return token_info
	else
		return nil, 'Wrong token.'
	end
end

local function find_show(ids, id)
	local id = tonumber(id)
	for i, v in next, ids do
		if tonumber(v.id) == id then
			return i
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
			local list_info = _DB:query('ningyou.lists', { user = username }, { name = 1, type = 1, _id = 0 })
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
			local list_lower = list:lower()
			local episode = tonumber(episode)

			local list_info = _DB:find_one("ningyou.lists", { user = username, name_lower = list_lower, ['ids.id'] = id })
			if not list_info then return err('Unable to find id %d in list %s', id, list), true end

			local key = ("%s:%d"):format(sites[list_info.type].name, id)
			local show_info = client:command('get', key)

			for i = 1, #show_info, 2 do
				show_info[show_info[i]] = show_info[i+1]
				show_info[i] = nil
				show_info[i+1] = nil
			end

			local total
			if show_info.enddate then
				total = show_info.episodecount or "N/A"
			elseif show_info.status and show_info.status ~= "Continuing" then
				total = client:hget(key, "episodecount") or "N/A"
			end

			local status = show_info.status
			local statuschange
			if total and episode >= tonumber(total) then
				episode = total
				status = "Completed"
			end

			local success, err = listlib:updateshow(list, id, 'episodes', episode)
			if not success then return err('Unable to add id %d to list %s, try again later', id, list), true end

			if status then
				success, err = listlib:updateshow(list, id, 'status', status)
			end
			if not success then return err('Unable to change status of id %d in list %s, try again later', id, list), true end

			content:write(json.encode({ result = "success", id = id, episode = episode, status = status }))
		end,
		addshow = function(token, list, id, episode, status)
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

			local idx = find_show(list_info['ids'], id)
			local show = list_info.ids[idx]
			local key = ("%s:%d"):format(sites[list_info.type].name, id)
			local show_info = client:command('hgetall', key)

			for i = 1, #show_info, 2 do
				show_info[show_info[i]] = show_info[i+1]
				show_info[i] = nil
				show_info[i+1] = nil
			end

			if show_info.enddate then
				show.total = show_info.episodecount or "N/A"
			elseif show_info.status and show_info.status ~= "Continuing" then
				show.total = show_info.episodecount or "N/A"
			end

			show.title = listlib:show_title(tonumber(id), sites[list_info.type].name)

			content:write(json.encode(show))
		end,
		getlist = function(token, list, username)
			if not token then return err'No token defined', true end
			if not list then return err'No list defined', true end

			local token, fail = check_token(token)
			if not token then return err(fail), true end

			local check_user = username or token['user']
			local username = user:Exists(check_user)
			if not username then return err('Username %s not found.', check_user), true end

			local lists = listlib:getlist(username, list)
			if not lists then return err('Unable to find list: %s', list) end

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
