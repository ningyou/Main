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
local db = require'db'

local env = {
	logged_user_id = sessions.user_id,
	logged_user = sessions.username,
}

local function format_history(info)
	local strings = dofile'config/history.lua'
	local list_info = _DB:find_one('ningyou.lists', { user = info.user, name_lower = info.list:lower() }, { name = 1, type = 1, _id = 0 })
	if (not list_info or not info) then return end
	
	local show_title = listlib:show_title(tonumber(info.id), sites[list_info.type].name) or 'N/A'
	if type(show_title) ~= "string" then return end

	return strings[info.action][info.type]:format(list_info.name, show_title, info.value or 0)
end

return {
	index = function(name, list)
		local username, user_id, user_title = user:Exists(name)
		if(not username) then return 404 end

		env['user'] = username
		env['user_id'] = user_id

		if list then
			local lists, list_name, list_type, list_id, list_url = listlib:getlist(user_id, list)
			if not lists then return 404 end

			env.lists = lists
			env.url = list_url
			env.list_name = list_name
			env.list_id = list_id

			env.status = db:unnest('status', list_id)
			env.order = db:unnest('order', list_id)

			env.json = json

			template:RenderView('list', env)
		else

			--[[
			local key = 'history:'..username
			local history = client:command('lrange', key, 0, -1)
			env.history = {}
			for i = #history, 1, -1 do
				local info = json.decode(history[i])
				info.user = username

				table.insert(env.history, { string = format_history(info), time = date('%c', info.time) })
			end
			]]

			local query = "select list.name, type.name from ningyou_lists as list, ningyou_list_types as type where type.id = list.type_id and list.user_id = %d"
			local res = _DB:execute(query:format(user_id))
			if res then
				env.lists = {}
				for list_name, list_type in db:results(res) do
					env.lists[#env.lists+1] = { name = list_name, type = list_type }
				end
				table.sort(env.lists, function(a,b) return a.name:lower() < b.name:lower() end)
			end
			env['user_title'] = user_title
			template:RenderView('user', env)
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
			local login, user_id = user:Login(_POST['name'], string.SHA256(_POST['password']))
			if login then
				sessions:Save(login, user_id, _POST.remember)
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
				if not _POST['submit'] then return template:RenderView('addlist', env) end

				local success, err = listlib:addlist(_POST.name, _POST.type)
				if not success then return content:write(err) end

				header('Location', '/')
				return setReturnCode(302)
			end,
			show = function()
				if not _POST.show_id then return end
				local success, err = listlib:addshow(sessions.user_id, _POST.list_id, _POST.show_id, _POST.episodes, _POST.status_id, _POST.rating)
			end,
			episode = function()
				if not _POST.show_id then return end
				local success, err = listlib:updateshow(sessions.user_id, _POST.list_id, _POST.show_id, _POST.episodes, _POST.status_id)
			end,
		}

		if not func[t] then return 404 end

		return func[t](), true
	end,

	del = function(_,t,n)
		if not sessions.username then return 404 end

		if t == 'show' then
			if not _POST.show_id then return end

			listlib:removeshow(sessions.user_id, _POST.list_id, _POST.show_id)
		elseif t == 'list' then
			local list = _POST.name or n
			if not list then return end

			listlib:removelist(list)
		end
	end,
}
