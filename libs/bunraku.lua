local zmq = require'zmq'

local _M = {}

function _M:Send(string)
	if type(string) ~= 'string' then return end
	local ctx = zmq.init(1)
	local s = ctx:socket(zmq.PUB)
	s:connect'ipc:///tmp/bunraku.sock'

	s:send(string)

	s:close()
	ctx:term()
end

return _M
