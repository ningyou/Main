local bunraku = require'bunraku'
local template = require'template'
local user = require'user'
local sessions = require'sessions'
local anidbsearch = require'anidbsearch'
local mangasearch = require'mangasearch'
local tvsearch = require'tvsearch'
local db = require'db'
local client = _CLIENT

local sites = dofile'config/sites.lua'

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
			elseif searchtype == "tv" then
				results = tvsearch.lookup(_POST["search"])
				url = "http://thetvdb.com/?tab=series&id="
			end

			if results then
				local not_in_cache = {}
				not_in_cache[1] = sites[searchtype].name
				for i = 1, #results do
					local key = ("%s:%d"):format(sites[searchtype].name, results[i].id)
					local show_info = _CLIENT:command('hgetall', key)

					for i = 1, #show_info, 2 do
						show_info[show_info[i]] = show_info[i+1]
						show_info[i] = nil
						show_info[i+1] = nil
					end

					local ttl = client:command('ttl', key)
					if #show_info == 0 and (ttl > 86400 or ttl == -1) then
						not_in_cache[#not_in_cache+1] = results[i].id
					end
					if searchtype == "tv" then
						results[i].type = "TV Series"
					else
						results[i].type = show_info.type or "N/A"
					end
					if show_info.enddate or searchtype == "tv" then
						results[i].total = show_info.episodecount or "N/A"
					end
				end

				if not_in_cache[2] then
					bunraku:Send(table.concat(not_in_cache, ","))
				end

				local query = "select list.id, list.name, type.name from ningyou_lists as list, ningyou_list_types as type where type.id = list.type_id and list.user_id = %d and LOWER(type.name) = '%s' order by list.name"
				local res, err = _DB:execute(query:format(sessions.user_id, searchtype))
				if err then return print(err) end

				local lists = {}
				for list_id, list_name, list_type in db:results(res) do
					lists[#lists+1] = { id = list_id, name = list_name, type = list_type, status = db:unnest('status', list_id) }
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
					logged_user = sessions.username,
					logged_user_id = sessions.user_id,
					status = status,
					selected_status = _POST["status"],
					episodes = _POST["episodes"],
				})

				return nil, true
			else
				echo("Could not find: " .. _POST["search"])
			end
		elseif sessions.username then
			template:RenderView('search', { logged_user = sessions.username })
		else
			return 404
		end
	end,
}
