local bunraku = require'bunraku'
local template = require'template'
local ob = require'ob'
local user = require'user'
local sessions = require'sessions'
local zlib = require'zlib'
local lom = require'lxp.lom'
local xpath = require'xpath'
local anidbsearch = require'anidbsearch'
require'redis'

local content = ob.Get'Content'

local user_env = {
	logged_user = user:Name(sessions.user_id),
	logged_user_id = sessions.user_id,
}

local function find_id(title, site)
	local r = _DB:find_one("ningyou." .. site .. "titles", { title_lower = title:lower() }, { [site.."_id"] = 1, _id = 0 })
	if r then return tonumber(r[site.."_id"]) end
end

local function find_title(id, site)
	local r = _DB:find_one("ningyou." .. site .. "titles", { [site.."_id"] = id, type = "main" }, { title = 1, _id = 0})
	if r then return r.title end
end

local function add_to_list(list, id, episodes, status, rating)
	local key = "lists.".. list .. ".ids."..id
	if not list and not id and not episodes and not status then return end
	if _DB:find_one("ningyou.lists", { user = user_env["logged_user"], [key] = { ["$exists"] = "true" }}) then return end

	return _DB:update("ningyou.lists", { user = user_env["logged_user"] }, { ["$set"] = { [key] = { episodes = episodes, status = status, rating = rating }}})
end

return {
	index = function(name)
		local user_id = user:ID(name)
		if not user_id then return 404 end

		user_env["user"] = user:Name(user_id)
		user_env["user_id"] = user_id
		template:RenderView('user', nil, user_env)
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
		if sessions.user_id then
			content:write("Already logged in as " .. user:Name(sessions.user_id))
		elseif _POST["submit"] then
			local uri = _POST["referer"] or "http://" .. getEnv()["Host"] .. "/"
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
		if not sessions.session_id then
			header("Location", "/")
			setReturnCode(302)
		else
			sessions:Delete(sessions.session_id)
			header("Location", "/")
			setReturnCode(302)
		end
	end,
	google_oauth_callback = function()
		content:write("More to come..")
	end,
	import = function()
		if _POST["import_file"] and _POST["site"] == "mal" then
			local xml = zlib.inflate() (_POST["import_file"][2])
			local xml_tree = lom.parse(xml)

			if xml_tree then
				local cache = Redis.connect('127.0.0.1', 6379)
				local animes = xpath.selectNodes(xml_tree, '/myanimelist/anime/')
				local nomatch = {}
				local list = {}
				local not_in_cache = {}
				table.insert(not_in_cache, "anidb")
				
				for _,t in pairs(animes) do
					local title = t[4][1]
					title = title:gsub("'", "`")
					title = title:gsub("%s(wo)%s", " o ")
					title = title:gsub("[%s%s]+", " ")

					local watched = t[12][1]
					local status = t[28][1]
					local id = find_id(title, "anidb")
					if not id then
						table.insert(nomatch, { title = title })
					else
						if not cache:exists("anidb:"..id) then
							table.insert(not_in_cache, id)
						end
						table.insert(list, id)
					end
				end

				echo"We found these:<br/>"
				for _,id in next, list do
					echo(find_title(id, "anidb") .. "<br/>")
				end
				echo"<br/>"
				echo"We didnt find:<br/>"
				for _,t in pairs(nomatch) do
					echo(t.title .. "<br/>")
				end

				echo"<br/>"
				echo(table.concat(not_in_cache, ","))
			end
		else
			template:RenderView('import', nil, user_env)
		end
	end,
	search = function()
		if _POST["search"] then
			local results = anidbsearch.lookup(_POST["search"])
			if results then
				template:RenderView('searchresults', nil, { results = results })
			else
				echo("Could not find: " .. _POST["search"])
			end
		else
			template:RenderView('search')
		end
	end,
}
