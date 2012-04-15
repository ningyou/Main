local bunraku = require'bunraku'
local template = require'template'
local user = require'user'
local sessions = require'sessions'
local anidbsearch = require'anidbsearch'
local mangasearch = require'mangasearch'
require'redis'

local sites = dofile'config/sites.lua'

local user_env = {
	logged_user = user:Name(sessions.user_id),
	logged_user_id = sessions.user_id,
}

return {
	search = function(_,searchtype)
		if _POST["search"] then
			local results
			local url

			if searchtype == "anime" then
				results = anidbsearch.lookup(_POST["search"])
				url = "http://anidb.net/a"
			elseif searchtype == "manga" then
				results = mangasearch.lookup(_POST["search"])
				url = "http://www.animenewsnetwork.com/encyclopedia/anime.php?id="
			end

			if results then
				local not_in_cache = {}
				table.insert(not_in_cache, sites[searchtype])
				local cache = Redis.connect('127.0.0.1', 6379)
				for i = 1, #results do
					local key = sites[searchtype]..":"..results[i].id
					if not (cache:exists(key) and (cache:ttl(key) > 86400 or cache:ttl(key) == -1)) then
						table.insert(not_in_cache, results[i].id)
					end
					results[i].type = cache:hget(key, "type") or "N/A"
					if cache:hexists(key, "enddate") then
						results[i].total = cache:hget(key, "episodecount") or "N/A"
					end
				end
				cache:quit()

				if not_in_cache[2] then
					local send = table.concat(not_in_cache, ",")
					bunraku:Send(send)
				end
				local list_info = _DB:find_one("ningyou.lists", { user = user_env["logged_user"]:lower() }, { ["lists"] = 1 })
				local lists = {}

				if list_info then
					for name, info in next, list_info.lists do
						table.insert(lists, { name = info.name, type = info.type, name_lower = name })
					end
					table.sort(lists, function(a,b) return a.name:lower() < b.name:lower() end)
				end

				local status = {
					"Watching",
					"Completed",
					"Plan to Watch",
					"On-Hold",
					"Dropped",
				}

				template:RenderView('searchresults', {
					results = results,
					url = url,
					lists = lists,
					logged_user = user:Name(sessions.user_id),
					status = status,
					selected_status = _POST["status"],
					episodes = _POST["episodes"],
				})

				return nil, true
			else
				echo("Could not find: " .. _POST["search"])
			end
		elseif sessions.user_id then
			template:RenderView('search', user_env)
		else
			return 404
		end
	end,
}
