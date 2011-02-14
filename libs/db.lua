require"mongo"

local _M = mongo.Connection.New()

_M:connect"localhost"

function _M:TitleFromID(id, type, lang or "main")
	local q = self:query("ningyou.titles", { _id = id })

	for r in q:results() do
		return q.lang[lang]
	end

	return
end

return _M
