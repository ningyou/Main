local ob = require'ob'
local cookies = require'cookies'

return {
	index = function()
		local env = getEnv()
		ob.Get'Content':write'<pre>'
		for k,v in next, env do
			ob.Get'Content':write(k, ' = ', v, '\n')
		end

		ob.Get'Content':write'_GET:\n'
		for k,v in next, _GET do
			ob.Get'Content':write(k, ' = ', v, '\n')
		end

		ob.Get'Content':write'_POST:\n'
		for k,v in next, _POST do
			ob.Get'Content':write(k, ' = ', v, '\n')
		end

		ob.Get'Content':write'</pre>'
	end,
}
