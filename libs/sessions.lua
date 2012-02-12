local db = require"db"
local cookie = require"cookies"

local _M = {}

function _M:Save(user_id)
	local session_id = string.SHA256(math.random(1305534,30598239) .. os.time())

	db:insert("ningyou.sessions", { session_id = session_id, user_id = user_id, _padding = ("x"):rep(100) })
	cookie:Set("session_id", session_id)

	return session_id
end

function _M:Get(session_id)
	local r = db:find_one("ningyou.sessions", { session_id = session_id })

	if r and r.user_id then
		db:update("ningyou.sessions", { session_id = session_id }, { session_id = session_id, user_id = r.user_id })
		return r.user_id
	else
		return
	end
end

function _M:Init()
	local session_id = cookie:Get("session_id")

	_M.user_id = nil

	if session_id then
		_M.user_id = self:Get(session_id)
	end
end

return _M
