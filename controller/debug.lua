local ob = require'ob'
local cookies = require'cookies'
local request = require'request'

return {
	index = function()
		local h = assert(io.popen('env', 'r'))
		local o = h:read'*all'

		ob.Get'Content':write'<pre>'
		ob.Get'Content':write(o)

		ob.Get'Content':write'_GET:\n'
		for k,v in next, request._GET do
			ob.Get'Content':write(k, ' = ', v, '\n')
		end

		ob.Get'Content':write'_POST:\n'
		for k,v in next, request._POST do
			ob.Get'Content':write(k, ' = ', v, '\n')
		end

		ob.Get'Content':write'</pre>'
	end,
}
