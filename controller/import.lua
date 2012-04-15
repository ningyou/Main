local bunraku = require'bunraku'
local template = require'template'
local user = require'user'
local zlib = require'zlib'
local sessions = require'sessions'
local lom = require'lxp.lom'
local xpath = require'xpath'
require'redis'

local user_env = {
	logged_user = user:Name(sessions.user_id),
	logged_user_id = sessions.user_id,
}

local function find_id(title, site)
	local r = _DB:find_one("ningyou." .. site .. "titles", { title_lower = title:lower() }, { [site.."_id"] = 1, _id = 0 })
	if r then return tonumber(r[site.."_id"]) end
end

local function add_to_list(list, id, episodes, status, rating)
	local key = "lists.".. list:lower() .. ".ids."..id
	if not list and not id and not episodes and not status then return end
	if _DB:find_one("ningyou.lists", { user = user_env["logged_user"]:lower(), [key] = { ["$exists"] = "true" }}) then return end

	return _DB:update("ningyou.lists", { user = user_env["logged_user"]:lower() }, { ["$set"] = { [key] = { episodes = episodes, status = status, rating = rating }}})
end

local importers = {
	anidb = function()
		local xml = _POST["import_file"][2]
		xml = xml:gsub("<export .* />", "")
		local xml_tree = lom.parse(xml)

		if xml_tree then
			local cache = Redis.connect('127.0.0.1', 6379)
			local animes = xpath.selectNodes(xml_tree, '/anime/entry/')
			local added_count = 0
			local not_in_cache = {}

			for _,t in next, animes do
				local episodes = t.attr.eps
				local id = t.attr.id
				local completed = tonumber(t.attr.is_watched)
				local status

				if completed == 1 then
					status = "Completed"
				else
					status = "Watching"
				end

				local key = "anidb:"..id
				if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
					table.insert(not_in_cache, id)
				end
				local added = add_to_list(_POST["list"], id, episodes, status)
				if added then
					added_count = added_count+1
				end
			end
			cache:quit()

			if not_in_cache[2] then
				local send = table.concat(not_in_cache, ",")
				bunraku:Send(send)
			end

			user_env["added_count"] = added_count
			user_env["list"] = _POST["list"]

			template:RenderView('importresults', user_env)
		end
	end,

	mal = function()
		local xml = zlib.inflate() (_POST["import_file"][2])
		local xml_tree = lom.parse(xml)

		if xml_tree then
			local cache = Redis.connect('127.0.0.1', 6379)
			local animes = xpath.selectNodes(xml_tree, '/myanimelist/anime/')
			local nomatch = {}
			local added_count = 0
			local not_in_cache = {}
			table.insert(not_in_cache, "anidb")

			for _,t in pairs(animes) do
				local title = t[4][1]
				title = title:gsub("'", "`")
				title = title:gsub("%s(wo)%s", " o ")
				title = title:gsub("[%s%s]+", " ")

				local watched = t[12][1]
				local rating = t[18][1]
				local status = t[28][1]
				local id = find_id(title, "anidb")
				if not id then
					table.insert(nomatch, { title = title, episodes = watched, status = status })
				else
					local key = "anidb:"..id
					if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
						table.insert(not_in_cache, id)
					end
					local added = add_to_list(_POST["list"], id, watched, status, rating)
					if added then
						added_count = added_count+1
					end
				end
			end

			cache:quit()

			if not_in_cache[2] then
				local send = table.concat(not_in_cache, ",")
				bunraku:Send(send)
			end

			user_env["nomatch"] = nomatch
			user_env["added_count"] = added_count
			user_env["list"] = _POST["list"]

			template:RenderView('importresults', user_env)
		end
	end,
}

return {
	import = function()
		local import_file = _POST['import_file']
		local site = _POST['site']

		if(import_file and importers[site]) then
			return importers[site]()
		elseif sessions.user_id then
			local lists = _DB:find_one("ningyou.lists", { user = user_env["logged_user"] })
			if lists then
				user_env.lists = lists.lists
			end
			template:RenderView('import', user_env)
		else
			return 404
		end
	end,
}
