local db = require"db"
local cookie = require"cookies"

local _M = {}

function _M:save(uid)
	local id = mongo.GenerateID()

	db:insert("ningyou.sessions", { _id = mongo.ObjectId(id), uid = uid, _padding = ("x"):rep(100) })
	
	return id
end

function _M:get(id)
	id = mongo.ObjectId(id)

	local r = db:query("ningyou.sessions", { _id = id }):results()()

	if r and r.uid then
		db:update("ningyou.sessions", { _id = id }, { _id = id, uid = r.uid })
		return r.uid
	end
end

function _M:Init()
	local sid = cookie:Get("sid")

	if sid then
		_M.ID = self:get(sid)
	end
end

return _M
