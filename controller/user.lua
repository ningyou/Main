local bunraku = require'bunraku'
local template = require'template'
local ob = require'ob'
local user = require'user'
local listlib = require'list'
local sessions = require'sessions'
local json = require'json'
local content = ob.Get'Content'
local mp = require'cmsgpack'
local date = os.date
local sites = dofile'config/sites.lua'
local client = _CLIENT

local user_env = {
	logged_user = sessions.username,
}

local function format_history(info)
	local strings = dofile'config/history.lua'
	local list_info = _DB:find_one('ningyou.lists', { user = info.user, name_lower = info.list:lower() }, { name = 1, type = 1, _id = 0 })

	if (not list_info or not info) then return end

	return strings[info.action][info.type]:format(list_info.name, listlib:show_title(tonumber(info.id), sites[list_info.type].name) or 'N/A', info.value or 0)
end

return {
	index = function(name, list)
		local username = user:Exists(name)
		if(not username) then return 404 end

		user_env['user'] = username

		if list then
			local list = list:lower()
			local lists, list_type = listlib:getlist(username, list)
			if not lists then return 404 end

			user_env.lists = lists
			user_env.url = sites[list_type].url
			user_env.list_name = _DB:find_one('ningyou.lists', { user = username, name_lower = list }, { name = 1, _id = 0 }).name

			-- Fix sorting.
			user_env.status = {
				'Watching',
				'Completed',
				'Plan to Watch',
				'On-Hold',
				'Dropped',
			}

			template:RenderView('list', user_env)
		else
			local key = 'history:'..username
			local history = client:command('lrange', key, 0, -1)
			user_env.history = {}
			for i = #history, 1, -1 do
				local info = json.decode(history[i])
				info.user = username

				table.insert(user_env.history, { string = format_history(info), time = date('%c', info.time) })
			end

			local list_info = _DB:query('ningyou.lists', { user = username }, nil, nil, { name_lower = 1, name = 1, type = 1 })

			if list_info then
				user_env.lists = {}
				for info in list_info:results() do
					table.insert(user_env.lists, { name = info.name, type = info.type, name_lower = info.name_lower })
				end
				table.sort(user_env.lists, function(a,b) return a.name:lower() < b.name:lower() end)
			end
			user_env['user_title'] = _DB:find_one('ningyou.users', { name = username }, { title = 1 }).title
			template:RenderView('user', user_env)
		end
	end,

	signup = function()
		if _POST['submit'] then
			local register, err = user:Register(_POST['name'], _POST['password'], _POST['mail'])
			if register then
				content:write('Success!')
			else
				content:write(err)
			end
		else
			template:RenderView('signup')
		end
	end,

	login = function()
		if sessions.username then
			content:write('Already logged in as ' .. sessions.username)
		elseif _POST['submit'] then
			local uri = getEnv()['Referer']
			local login = user:Login(_POST['name'], string.SHA256(_POST['password']))
			if login then
				sessions:Save(login, _POST.remember)
				header('Location', uri)
				setReturnCode(302)
			else
				content:write('Wrong Username or Password')
			end
		else
			template:RenderView('login')
		end
	end,

	logout = function()
		if sessions.session_id then
			sessions:Delete(sessions.session_id)
		end

		header('Location', '/')
		setReturnCode(302)
	end,

	google_oauth_callback = function()
		content:write('More to come..')
	end,

	add = function(_,t)
		-- TODO: Change this to some access denied return code.
		if not sessions.username then return 404 end

		local func = {
			list = function()
				if not _POST['submit'] then return template:RenderView('addlist', user_env) end

				local success, err = listlib:addlist(_POST.name, _POST.type)
				if not success then return content:write(err) end

				header('Location', '/')
				return setReturnCode(302)
			end,
			show = function()
				local success, err = listlib:addshow(_POST.list_name, _POST.id, _POST.episodes, _POST.status, _POST.rating)
			end,
			episode = function()
				if not _POST.id then return end
				if _POST.episodes then
					local success, err = listlib:updateshow(_POST.list_name, _POST.id, 'episodes', _POST.episodes)
				end
				if _POST.statuschange == 'true' then
					listlib:updateshow(_POST.list_name, _POST.id, 'status', _POST.status)
				end
			end,
		}

		if not func[t] then return 404 end

		return func[t](), true
	end,

	del = function(_,t,n)
		if not sessions.username then return 404 end

		if t == 'show' then
			if not _POST.id then return end

			listlib:removeshow(_POST.list_name, _POST.id)
		elseif t == 'list' then
			local list = _POST.name or n
			if not list then return end

			listlib:removelist(list)
		end
	end,
}
