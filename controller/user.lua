local bunraku = require'bunraku'
local template = require'template'
local ob = require'ob'
local user = require'user'
local sessions = require'sessions'
local json = require'json'
require'redis'

local content = ob.Get'Content'

local sites = dofile'config/sites.lua'

local user_env = {
	logged_user = sessions.username,
}

local function find_title(id, site)
	local r = _DB:find_one("ningyou." .. site .. "titles", { [site.."_id"] = id, type = "official", lang = "en" }, { title = 1, _id = 0}) or _DB:find_one("ningyou." .. site .. "titles", { [site.."_id"] = id, type = "main" }, { title = 1, _id = 0})
	if r then return r.title end
end

local function format_history(info)
	local strings = dofile'config/history.lua'
	local list_info = _DB:find_one("ningyou.lists", { user = info.user, name_lower = info.list }, { name = 1, type = 1, _id = 0 })

	if (not list_info or not info) then return end

	return strings[info.action][info.type]:format(list_info.name, find_title(tonumber(info.id), sites[list_info.type]), info.value)
end

local function add_episode(user, list, id, info)
	local list = list:lower()

	if _DB:find_one("ningyou.lists", { user = user, name_lower = list, ["ids.id"] = id }) then return end

	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
	}, {
		["$push"] = {
			ids = {
				id = id,
				status = info.status,
				episodes = info.episodes,
				rating, info.rating,
			}
		}
	})

	if success then
		local client = Redis.connect('127.0.0.1', 6379)
		client:rpush("history:"..sessions.username, json.encode({
			time = os.time(),
			action = "add",
			type = "show",
			list = list,
			id = id,
			value = info.status,
		}))
		client:quit()
	end

	return success, err
end

local function update_episode(user, list, id, info)
	local list = list:lower()

	if not _DB:find_one("ningyou.lists", { user = user, name_lower = list, ["ids.id"] = id }) then return end

	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
		["ids.id"] = id,
	}, {
		["$set"] = {
			["ids.$.episodes"] = info.episodes,
			["ids.$.status"] = info.status,
			["ids.$.rating"] = info.rating,
		}
	})

	local client = Redis.connect('127.0.0.1', 6379)
	if success and info.episodes then
		client:rpush("history:"..sessions.username, json.encode({
			time = os.time(),
			action = "update",
			type = "episode",
			list = list,
			id = id,
			value = info.episodes,
		}))
	end
	if success and info.statuschange == "true" then
		client:rpush("history:"..sessions.username, json.encode({
			time = os.time(),
			action = "update",
			type = "status",
			list = list,
			id = id,
			value = info.status,
		}))

	end
	client:quit()

	return success, err
end

return {
	index = function(name, list)
		local username = user:Exists(name)
		if(not username) then return 404 end

		user_env["user"] = username

		if list then
			list = list:lower()
			local list_info = _DB:find_one("ningyou.lists", { user = username, name_lower = list })
			if not list_info then return 404 end

			local cache = Redis.connect('127.0.0.1', 6379)
			user_env.lists = {}
			local not_in_cache = {}
			table.insert(not_in_cache, sites[list_info.type])

			if list_info.ids then
				for _, info in next, list_info.ids do
					local key = sites[list_info.type]..":"..info.id
					if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
						table.insert(not_in_cache, info.id)
					end

					local key = sites[list_info.type]..":"..info.id
					local today = os.date('%Y-%m-%d')
					if not user_env.lists[info.status] then user_env.lists[info.status] = {} end
					info.title = find_title(tonumber(info.id), sites[list_info.type])
					info.type = cache:hget(key, "type") or "N/A"
					if cache:hexists(key, "enddate") then
						info.total = cache:hget(key, "episodecount") or "N/A"
						info.aired = cache:hget(key, "enddate") < today
					end
					if cache:hexists(key, "startdate") and cache:hget(key, "startdate"):match"%d+-%d+-%d+" then
						info.notyet = cache:hget(key, "startdate") > today
						info.startdate = cache:hget(key, "startdate")
					else
						info.notyet = true
					end
					table.insert(user_env.lists[info.status], info)
				end
				for _, ids in next, user_env.lists do
					table.sort(ids, function(a,b) return a.title:lower() < b.title:lower() end)
				end
			end

			user_env.list_name = list_info.name
			user_env.status = {
				"Watching",
				"Completed",
				"Plan to Watch",
				"On-Hold",
				"Dropped",
			}

			if not_in_cache[2] then
				local send = table.concat(not_in_cache, ",")
				bunraku:Send(send)
			end

			cache:quit()
			template:RenderView('list', user_env)
		else
			local client = Redis.connect('127.0.0.1', 6379)
			local key = "history:"..username
			local history = client:lrange(key, 0, -1)
			user_env.history = {}
			for i = #history, 1, -1 do
				local info = json.decode(history[i])
				info.user = username

				table.insert(user_env.history, { string = format_history(info), time = os.date("%c", info.time) })
			end

			local list_info = _DB:query("ningyou.lists", { user = username }, nil, nil, { name_lower = 1, name = 1, type = 1 })

			if list_info then
				user_env.lists = {}
				for info in list_info:results() do
					table.insert(user_env.lists, { name = info.name, type = info.type, name_lower = info.name_lower })
				end
				table.sort(user_env.lists, function(a,b) return a.name:lower() < b.name:lower() end)
			end
			client:quit()
			template:RenderView('user', user_env)
		end
	end,

	signup = function()
		if _POST["submit"] then
			local register, err = user:Register(_POST["name"], _POST["password"], _POST["mail"])
			if register then
				content:write("Success!")
			else
				content:write(err)
			end
		else
			template:RenderView('signup')
		end
	end,

	login = function()
		if sessions.username then
			content:write("Already logged in as " .. sessions.username)
		elseif _POST["submit"] then
			local uri = getEnv()["Referer"]
			local login = user:Login(_POST["name"], string.SHA256(_POST["password"]))
			if login then
				local timeout
				if not _POST["remember"] then timeout = (os.time() + 7200) end
				sessions:Save(login, timeout)
				header("Location", uri)
				setReturnCode(302)
			else
				content:write("Wrong Username or Password")
			end
		else
			template:RenderView('login')
		end
	end,

	logout = function()
		if sessions.session_id then
			sessions:Delete(sessions.session_id)
		end

		header("Location", "/")
		setReturnCode(302)
	end,

	google_oauth_callback = function()
		content:write("More to come..")
	end,

	add = function(_,t)
		if t == "list" then
			if _POST["submit"] then
				local list = _POST.name:lower()
				if _DB:find_one("ningyou.lists", { user = sessions.username, name_lower = list }) then
					header("Location", "/")
					return setReturnCode(302)
				end

				_DB:insert("ningyou.lists", { user = sessions.username, name = _POST.name, type = _POST.type, name_lower = list })

				header("Location", "/")
				return setReturnCode(302)
			else
				template:RenderView('addlist', user_env)
			end
		end

		if t == "show" then
			if not sessions.username then return end

			add_episode(sessions.username, _POST.list_name, _POST.id, {
				status = _POST.status,
				episodes = _POST.episodes,
				rating = _POST.rating,
			})
		end
		if t == "episode" then
			if not sessions.username then return end

			if _POST.id then
				local success, err = update_episode(sessions.username, _POST.list_name, _POST.id, {
					episodes = _POST.episodes,
					status = _POST.status,
					statuschange = _POST.statuschange,
				})
			end
		end
		return nil, true
	end,

	del = function(_,t,n)
		if not sessions.username then return end

		if t == "show" then
			if _POST.id then
				_DB:update("ningyou.lists", {
					user = sessions.username,
					name_lower = _POST.list_name:lower(),
					["ids.id"] = _POST.id
				}, {
					["$unset"] = {
						["ids.$"] = 1,
					}
				})
				-- Remove the null left by $unset.
				_DB:update("ningyou.lists", {
					user = sessions.username,
					name_lower = _POST.list_name:lower(),
				}, {
					["$pull"] = {
						ids = mongo.NULL(),
					}
				})
			end
		elseif t == "list" then
			if _POST.name then
				if not _DB:find_one("ningyou.lists", { user = sessions.username, name_lower = _POST.name:lower() }) then return end

				_DB:remove("ningyou.lists", {
					user = sessions.username,
					name_lower = _POST.name:lower(),
				}, true)
			elseif n then
				if not _DB:find_one("ningyou.lists", { user = sessions.username, name_lower = n:lower() }) then return end

				_DB:remove("ningyou.lists", {
					user = sessions.username,
					name_lower = n:lower(),
				}, true)
			end
		end
	end,
}
