local lfcgi = require'lfcgi'

local _M = {}

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
		if(key and value) then
			request[key] = urlDecode(value)
		end
	end)

	return request
end

local injectFields = function(tbl, str)
	str:gsub('[^;]+', function(entry)
		local key, value = entry:match'%s*([^=]+)="(.*)"$'
		tbl[key:lower()] = value
	end)
end

local doGet = function()
	local get_query = os.getenv'QUERY_STRING' or ''
	_M._GET = parseRequest(get_query)
end

local doPost = function()
	local method = _M.method
	local contentType = _M.contentType

	_M._POST = {}
	local _POST = _M._POST

	if(method == 'POST') then
		if(contentType == 'application/x-www-form-urlencoded') then
			_POST = parseRequest(io.stdin:read'*a')
		elseif(contentType:match('multipart/form%-data')) then
			local data
			if(magnet) then
				data = lfcgi.stdin
			else
				data = io.stdin
			end

			local boundary = contentType:match'boundary=%-*([0-9A-Za-z]+)'
			local boundaryPattern = '%-*' .. boundary

			local _FILE = {}
			local tmp
			local fields = true
			for line in data:lines() do
				local boundary = line:match(boundaryPattern)
				if(boundary) then
					if(tmp) then
						if(tmp['content-type']) then
							-- Pop off the EOF newline.
							table.remove(tmp.content)
							tmp.content = table.concat(tmp.content, '\n')
							table.insert(_FILE, tmp)
						else
							-- How safe is this :D ?
							_POST[tmp.name] = tmp.content[1]
						end
					end

					-- Next please
					tmp = {content = {}}
					fields = true
				else
					if(fields) then
						if(line == '\r') then
							fields = nil
						else
							local field, value, extra = line:match'([^:]+):([^;]*);?(.*)\r'
							tmp[field:lower()] = value
							if(extra ~= '') then
								injectFields(tmp, extra)
							end
						end
					else
						table.insert(tmp.content, line)
					end
				end
			end

			_M._FILE = _FILE
		end
	end
end

function _M:Init()
	local method = os.getenv'REQUEST_METHOD'
	local contentType = os.getenv'CONTENT_TYPE'
	local contentLength = os.getenv'CONTENT_LENGTH'

	_M.method = method
	_M.contentType = contentType
	_M.contentLength = contentLength

	doPost()
	doGet()
end

return _M
