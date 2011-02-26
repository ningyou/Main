local db = require"db"

local _M = {}

function _M:save(uid)
	if not type(uid) == "number" then return end

	local id = mongo.GenerateID()

	db:insert("ningyou.sessions", { _id = mongo.ObjectId(id), uid = uid, _padding = ("x"):rep(100) })
	
	return id
end

function _M:get(id)
	id = mongo.ObjectId(id)

	local q = db:query("ningyou.sessions", { _id = id })

	local r = q:results()()

	db:update("ningyou.sessions", { _id = id }, { _id = id, uid = r.uid })
	return r.uid
end

return _M