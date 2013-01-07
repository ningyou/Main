local bunraku = require'bunraku'
local template = require'template'
local ob = require'ob'
local user = require'user'
local listlib = require'list'
local sessions = require'sessions'
local json = require'json'
local content = ob.Get'Content'

local sites = dofile'config/sites.lua'
local client = _CLIENT

local user_env = {
	logged_user = sessions.username,
}

local function format_history(info)
	local strings = dofile'config/history.lua'
	local list_info = _DB:find_one("ningyou.lists", { user = info.user, name_lower = info.list:lower() }, { name = 1, type = 1, _id = 0 })

	if (not list_info or not info) then return end

	return strings[info.action][info.type]:format(list_info.name, listlib:show_title(tonumber(info.id), sites[list_info.type]) or "", info.value or 0)
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

			user_env.lists = {}
			local not_in_cache = {}
			table.insert(not_in_cache, sites[list_info.type])

			-- Fix this.
			if list_info.type == "anime" then
				user_env.url = "http://anidb.net/a"
			elseif list_info.type == "manga" then
				user_env.url = "http://www.animenewsnetwork.com/encyclopedia/anime.php?id="
			elseif list_info.type == "tv" then
				user_env.url = "http://thetvdb.com/?tab=series&id="
			end

			if list_info.ids then
				for _, info in next, list_info.ids do
					local key = ("%s:%d"):format(sites[list_info.type], info.id)
					if not (client:command('exists', key) == 1 and (client:command('ttl', key) > 86400 or client:command('ttl', key) == -1)) then
						table.insert(not_in_cache, info.id)
					end

					local show_info = client:command("hgetall", key)
					-- Arrange the return as key = value
					for i = 1, #show_info, 2 do
						show_info[show_info[i]] = show_info[i+1]
						show_info[i] = nil
						show_info[i+1] = nil
					end

					local today = os.date('%Y-%m-%d')
					if not user_env.lists[info.status] then user_env.lists[info.status] = {} end
					info.title = listlib:show_title(tonumber(info.id), sites[list_info.type]) or "N/A"
					if list_info.type == "tv" then
						info.type = "TV Series"
					else
						info.type = show_info.type or "N/A"
					end
					if show_info.enddate then
						info.total = show_info.episodecount or "N/A"
						info.aired = show_info.enddate < today
					elseif show_info.status and show_info.status ~= "Continuing" then
						info.total = client:command('hget', key, "episodecount") or "N/A"
						info.aired = true
					end
					if show_info.startdate and show_info.startdate:match"%d+-%d+-%d+" then
						info.notyet = show_info.startdate > today
						info.startdate = show_info.startdate
					elseif show_info.status and status == "Continuing" then
						info.notyet = false
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

			template:RenderView('list', user_env)
		else
			local key = "history:"..username
			local history = client:command('lrange', key, 0, -1)
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
			user_env["user_title"] = _DB:find_one("ningyou.users", { name = username }, { title = 1 }).title
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
				if not _POST["remember"] then timeout = os.time()+7200 end
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
		-- TODO: Change this to some access denied return code.
		if not sessions.username then return 404 end

		local func = {
			list = function()
				if not _POST["submit"] then return template:RenderView('addlist', user_env) end

				local success, err = listlib:addlist(_POST.name, _POST.type)
				if not success then return content:write(err) end

				header("Location", "/")
				return setReturnCode(302)
			end,
			show = function()
				local success, err = listlib:addshow(_POST.list_name, _POST.id, _POST.episodes, _POST.status, _POST.rating)
			end,
			episode = function()
				if not _POST.id then return end
				if _POST.episodes then
					local success, err = listlib:updateshow(_POST.list_name, _POST.id, "episodes", _POST.episodes)
				end
				if _POST.statuschange == "true" then
					listlib:updateshow(_POST.list_name, _POST.id, "status", _POST.status)
				end
			end,
		}

		if not func[t] then return 404 end

		return func[t](), true
	end,

	del = function(_,t,n)
		if not sessions.username then return 404 end

		if t == "show" then
			if not _POST.id then return end

			listlib:removeshow(_POST.list_name, _POST.id)
		elseif t == "list" then
			local list = _POST.name or n
			if not list then return end

			listlib:removelist(list)
		end
	end,
}
