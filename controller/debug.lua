local ob = require'ob'
local cookies = require'cookies'

return {
	index = function()
		local h = assert(io.popen('env', 'r'))
		local o = h:read'*all'

		ob.Get'Content':write('<pre>', o, '</pre>')
		cookies:Set('user', 'haste', 'expires', os.time()+60)
		cookies:Set('status', 'fail', 'expires', os.time()+60)
	end,
}
