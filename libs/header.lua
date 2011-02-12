local ob = require'ob'

local headerFields = {
	['Content-Type'] = 'text/html',
}

local _M = {}

function _M:Generate()
	local buffer = ob.Get'Header'
	for key, value in next, headerFields do
		buffer:write(key, ': ', value, next(headerFields, key) and '\r\n')
	end

	buffer:write'\n\n'
end

return _M
