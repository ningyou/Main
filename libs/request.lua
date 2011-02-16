local method = os.getenv'REQUEST_METHOD'
local _GET ={}
local _POST = {}

local urlDecode
do
	local fmt = function(h) return string.char(tonumber(h,16)) end
	function urlDecode(str)
		if(str) then
			str = str:gsub("+", " ")
			str = str:gsub("%%(%x%x)", fmt)
			str = str:gsub("\r\n", "\n")
		end

		return str
	end
end

local parseRequest = function(str)
	local request = {}
	str:gsub('[^&]+', function(entry)
		local key, value = entry:match'([^=]+)=(.*)$'
		request[key] = urlDecode(value)
	end)

	return request
end

local get_query = os.getenv'QUERY_STRING'
if(#get_query > 0) then
	_GET = parseRequest(get_query)
end

return {
	_POST = _POST,
	_GET = _GET,
	method = method,
}
