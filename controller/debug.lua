local ob = require'ob'

return {
	index = function()
		local h = assert(io.popen('env', 'r'))
		local o = h:read'*all'

		ob.Get'Content':write('<pre>', o, '</pre>')
	end,
}
