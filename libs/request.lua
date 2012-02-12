local _M = {}

function _M:Init()
	local env = getEnv()
	local method = env['Request-Method']
	local contentType = env['Content-Type']
	local contentLength = env['Content-Length']

	_M.method = method
	_M.contentType = contentType
	_M.contentLength = contentLength

	_M._GET = parseGet()
	_M._POST = parsePost()
end

return _M
