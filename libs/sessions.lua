local db = require"db"
local cookie = require"cookies"

local _M = {}

function _M:Save(user_id, timeout)
	local session_id = string.SHA256(math.random(1305534,30598239) .. os.time())

	db:insert("ningyou.sessions", { session_id = session_id, user_id = user_id, timeout = timeout})
	cookie:Set("session_id", session_id)

	return session_id
end

function _M:Get(session_id)
	local r = db:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.user_id then
		if r.timeout and r.timeout > os.time() then
			r.timeout = os.time()+7200
			db:update("ningyou.sessions", { session_id = session_id }, { ["$set"] = { timeout = r.timeout } })
		end
		return r.user_id, r.timeout
	else
		return
	end
end

function _M:Delete(session_id)
	local r = db:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.user_id then
		db:remove("ningyou.sessions", { session_id = session_id })
		cookie:Delete("session_id")
	else
		return
	end
end

function _M:Timeout(session_id, timeout)
	local r = db:find_one("ningyou.sessions", { session_id = session_id })
	if r and r.user_id then
		if timeout then
			db:update("ningyou.sessions", { session_id = session_id }, { ["$set"] = { timeout = timeout } })
		else
			db:update("ningyou.sessions", { session_id = session_id }, { ["$unset"] = { timeout = 1 } })
	end
end

function _M:Init()
	local session_id = cookie:Get("session_id")

	_M.user_id = nil
	_M.session_id = nil

	if session_id then
		local user_id, timeout = _M:Get(session_id)
		if not timeout or (timeout and timeout > os.time()) then
			_M.session_id = session_id
			_M.user_id = user_id
		else
			_M:Delete(session_id)
		end
	end
end

return _M
