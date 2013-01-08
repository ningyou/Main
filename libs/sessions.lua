local cookie = require"cookies"
local key = "session:%s"
local _M = {}

function _M:Save(username, remember)
	local session_id = string.SHA256(math.random(1305534,30598239) .. os.time())

	if not remember then
		_CLIENT:command("setex", key:format(session_id), 7200, username) -- 2 hours
	else
		_CLIENT:command("setex", key:format(session_id), 604800, username) -- 1 week
	end

	cookie:Set("session_id", session_id)

	return session_id
end

function _M:Get(session_id)
	local key = key:format(session_id)
	local username = _CLIENT:command("get", key)
	if type(username) == "table" then return end

	local ttl = _CLIENT:command("ttl", key)
	if ttl > 7200 then
		_CLIENT:command("expire", key, 604800)
	else
		_CLIENT:command("expire", key, 7200)
	end
	return username
end

function _M:Delete(session_id)
	_CLIENT:command("del", key:format(session_id))
	cookie:Delete("session_id")
	return true
end

function _M:Init()
	local session_id = cookie:Get("session_id")

	_M.username = nil
	_M.session_id = nil

	if session_id then
		local username = _M:Get(session_id)
		if username then
			_M.session_id = session_id
			_M.username = username
		else
			_M:Delete(session_id)
		end
	end
end

return _M
