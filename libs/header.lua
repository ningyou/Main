local ob = require'ob'

local headerEnd
if(magnet) then
	headerEnd = '\r\n\r\n'
else
	headerEnd = '\n\n'
end

-- This is just a short list over fields we might set multiple times. The later
-- definition should always override the previous.
local uniqueFields = {
	['Content-Type'] = true,
	['Status'] = true,
}

local headerFields

local _M = setmetatable({}, {
	__call = function(self, field, value)
		if(uniqueFields[field]) then
			for i=1, #headerFields do
				local key = unpack(headerFields[i])
				if(key == field) then
					headerFields[i] = {field, value}
					return
				end
			end
		end

		table.insert(headerFields, {field, value})
	end,
})

function _M:Generate()
	local buffer = ob.Get'Header'

	for i=1, #headerFields do
		local key, value = unpack(headerFields[i])
		buffer:write(key, ': ', value, headerFields[i + 1] and '\r\n')
	end

	buffer:write(headerEnd)
end

function _M:Redirect(url, code)
	if(not code) then code = 302 end

	self:Reset()
	self('Status', code)
	self('Location', url)

	return false, 'redirect'
end

function _M:Reset()
	headerFields = {}
end

function _M:Init()
	headerFields = {
		{'Content-Type', 'text/html'},
	}
end

return _M
