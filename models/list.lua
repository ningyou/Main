local _M = {}
local redis = require'redis'
local json = require'json'
local sessions = require'sessions'

--TODO: Change to msgpack.
local history = function(action, htype, list, id, value)
	local client = redis.connect()
	client:rpush("history:"..sessions.username, json.encode({
		time = os.time(),
		action = action,
		type = htype,
		list = list,
		id = id,
		value = value,
	}))
	client:quit()
end

-- TODO: Add language support.
function _M:show_title(id, site, lang)
	if site == "tvdb" then
		local client = redis.connect()
		local title = client:hget(site..":"..id, "title")
		client:quit()

		return title or "N/A"
	else
		local r =
		_DB:find_one("ningyou." .. site .. "titles", { [site.."_id"] = id, type = "official", lang = "en" }, { title = 1, _id = 0})
		or
		_DB:find_one("ningyou." .. site .. "titles", { [site.."_id"] = id, type = "main" }, { title = 1, _id = 0})

		if r then return r.title end
	end
end

function _M:addshow(list, id, episode, status, rating)
	local list = list:lower()
	local user = sessions.username
	if _DB:find_one("ningyou.lists", { user = user, name_lower = list, ["ids.id"] = id }) then return end

	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
	}, {
		["$push"] = {
			ids = {
				id = id,
				status = status,
				episodes = episode,
				rating = rating,
			}
		}
	})

	if not success then return nil, err end

	history("add", "show", list, id, status)

	return true
end

function _M:updateshow(list, id, attr, value)
	local list = list:lower()
	local user = sessions.username
	if not _DB:find_one("ningyou.lists", { user = user, name_lower = list, ["ids.id"] = id }) then return end

	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
		["ids.id"] = id,
	}, {
		["$set"] = {
			["ids.$."..attr] = value,
		}
	})

	if not success then return nil, err end

	history("update", attr, list, id, value)

	return true
end

-- TODO: Add history.
function _M:removeshow(list, id)
	local list = list:lower()
	local user = sessions.username

	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
		["ids.id"] = id
	}, {
		["$unset"] = {
			["ids.$"] = 1,
		}
	})
	if not success then return nil, err end

	-- Remove the null left by $unset.
	local success, err = _DB:update("ningyou.lists", {
		user = user,
		name_lower = list,
	}, {
		["$pull"] = {
			ids = mongo.NULL(),
		}
	})
	if not success then return nil, err end

	return true
end

function _M:addlist(list, list_type)
	local user = sessions.username
	if _DB:find_one("ningyou.lists", { user = user, name_lower = list:lower() }) then return nil, ('List "%s" already exists.'):format(list) end

	local success, err = _DB:insert("ningyou.lists", { user = user, name = list, type = list_type, name_lower = list:lower() })
	if not success then return nil, err end
	return true
end

function _M:removelist(list)
	local list = list:lower()
	local user = sessions.username
	if not _DB:find_one("ningyou.lists", { user = user, name_lower = list }) then return end

	local success, err = _DB:remove("ningyou.lists", { user = user, name_lower = list }, true)
	if not success then return nil, err end

	return true
end

return _M