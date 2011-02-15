local http = require"socket.http"
local ltn12 = require"ltn12"

local _M = {}

function _M:get(u)
	local t = {}
	local b, c, h = http.request{
		url = u,
		sink = ltn12.sink.table(t)
	}
	return table.concat(t), c, h
end

return _M
