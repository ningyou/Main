local bunraku = require'bunraku'
local template = require'template'
local ob = require'ob'
local user = require'user'
local sessions = require'sessions'
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

return {
	index = function(name, list)
		local username = user:Exists(name)
		if(not username) then return 404 end

		user_env["user"] = username

		if list then
			list = list:lower()
			local list_info = _DB:find_one("ningyou.lists", { user = username }, { ["lists."..list] = 1 })
			if not list_info then return 404 end
			list_info = list_info.lists[list]

			local cache = Redis.connect('127.0.0.1', 6379)
			user_env.lists = {}
			local not_in_cache = {}
			table.insert(not_in_cache, sites[list_info.type])

			if list_info.ids then
				for id, info in next, list_info.ids do
					local key = sites[list_info.type]..":"..id
					if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
						table.insert(not_in_cache, id)
					end

					local key = sites[list_info.type]..":"..id
					local today = os.date('%Y-%m-%d')
					if not user_env.lists[info.status] then user_env.lists[info.status] = {} end
					info.title = find_title(tonumber(id), sites[list_info.type])
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
					info.id = id
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
			local list_info = _DB:find_one("ningyou.lists", { user = username }, { ["lists"] = 1 })

			if list_info then
				user_env.lists = {}
				for name, info in next, list_info.lists do
					table.insert(user_env.lists, { name = info.name, type = info.type, name_lower = name })
				end
				table.sort(user_env.lists, function(a,b) return a.name:lower() < b.name:lower() end)
			end

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
				local key = "lists." .. _POST["name"]:lower()
				if _DB:find_one("ningyou.lists", { user = sessions.username, [key] = { ["$exists"] = "true" }}) then
					header("Location", "/")
					setReturnCode(302)
				end

				if not _DB:find_one("ningyou.lists", { user = sessions.username}) then
					_DB:insert("ningyou.lists", { user = sessions.username, lists = { [_POST["name"]:lower()] = { name = _POST["name"], type = _POST["type"] }}})
				else
					_DB:update("ningyou.lists", { user = sessions.username }, { ["$set"] = { [key] = { name = _POST["name"], type = _POST["type"] }}})
				end
				_DB:ensure_index("ningyou.lists", { user = 1 })
				header("Location", "/")
				setReturnCode(302)
			else
				template:RenderView('addlist', user_env)
			end
		end

		if t == "episode" then
			if sessions.username:lower() == _POST["user"]:lower() then
				if _POST["id"] and _POST["episodes"] then
					local key = "lists.".. _POST["list_name"]:lower() .. ".ids." .. _POST["id"] .. ".episodes"
					_DB:update("ningyou.lists", { user = _POST["user"] }, { ["$set"] = { [key] = _POST["episodes"] }})
				end
				if _POST["id"] and _POST["status"] then
					local status = _POST["status"]
					local key = "lists.".. _POST["list_name"]:lower() .. ".ids." .. _POST["id"] .. ".status"
					_DB:update("ningyou.lists", { user = _POST["user"] }, { ["$set"] = { [key] = status }})
				end
			end
		end
		return nil, true
	end,

	del = function(_,t,n)
		if t == "show" then
			if sessions.username == _POST["user"] then
				if _POST["id"] then
					local key = "lists.".. _POST["list_name"]:lower() .. ".ids." .. _POST["id"]
					_DB:update("ningyou.lists", { user = _POST["user"] }, { ["$unset"] = { [key] = 1 }})
				end
			end
		elseif t == "list" then
			if _POST["name"] then
				if sessions.username == _POST["user"] then
					local key = "lists." .. _POST["name"]:lower()
					_DB:update("ningyou.lists", { user = _POST["user"] }, { ["$unset"] = { [key] = 1 }})
				end
			elseif n then
				local key = "lists." .. n:lower()
				_DB:update("ningyou.lists", { user = sessions.username }, { ["$unset"] = { [key] = 1 }})
			end
		end
	end,
}
