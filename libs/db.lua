require"mongo"

local _M = mongo.Connection.New()

_M:connect"localhost"

return _M
