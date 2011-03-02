local ob = require'ob'

local headerFields

local _M = setmetatable({}, {
	__call = function(self, field, value)
		table.insert(headerFields, {field, value})
	end,
})

function _M:Generate()
	local buffer = ob.Get'Header'

	for i=1, #headerFields do
		local key, value = unpack(headerFields[i])
		buffer:write(key, ': ', value, headerFields[i + 1] and '\r\n')
	end

	buffer:write'\n\n'
end

function _M:Init()
	headerFields = {
		{'Content-Type', 'text/html'},
	}
end

return _M
