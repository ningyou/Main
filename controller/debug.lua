local ob = require'ob'
local cookies = require'cookies'

return {
	index = function()
		local h = assert(io.popen('env', 'r'))
		local o = h:read'*all'

		ob.Get'Content':write('<pre>', o, '</pre>')
	end,
}
