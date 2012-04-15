local cookie = require"cookies"

local _M = {}

function _M:Save(username, timeout)
	local session_id = string.SHA256(math.random(1305534,30598239) .. os.time())

	_DB:insert("ningyou.sessions", { session_id = session_id, name = username, timeout = timeout})
	_DB:ensure_index("ningyou.sessions", { session_id = 1 })
	cookie:Set("session_id", session_id)

	return session_id
end

function _M:Get(session_id)
	local r = _DB:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.name then
		if r.timeout and r.timeout > os.time() then
			r.timeout = os.time()+7200
			_DB:update("ningyou.sessions", { session_id = session_id }, { ["$set"] = { timeout = r.timeout } })
		end
		return r.name, r.timeout
	end
end

function _M:Delete(session_id)
	local r = _DB:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.name then
		_DB:remove("ningyou.sessions", { session_id = session_id })
		cookie:Delete("session_id")
	end
end

function _M:Timeout(session_id, timeout)
	local r = _DB:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.name then
		if timeout then
			_DB:update("ningyou.sessions", { session_id = session_id }, { ["$set"] = { timeout = timeout } })
		else
			_DB:update("ningyou.sessions", { session_id = session_id }, { ["$unset"] = { timeout = 1 } })
		end
	end
end

function _M:Init()
	local session_id = cookie:Get("session_id")

	_M.username = nil
	_M.session_id = nil

	if session_id then
		local username, timeout = _M:Get(session_id)
		if not timeout or (timeout and timeout > os.time()) then
			_M.session_id = session_id
			_M.username = username
		else
			_M:Delete(session_id)
		end
	end
end

return _M
