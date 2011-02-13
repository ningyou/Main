local header = require'header'
local _M = {}

local urlEncode
do
	local fmt = function (c) return ("%%%02X"):format(string.byte(c)) end
	function urlEncode(str)
		if (str) then
			str = str:gsub("\n", "\r\n")
			str = str:gsub("([^%w ])", fmt)
			str = str:gsub(" ", "+")
		end

		return str
	end
end

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

local handlers = {
	expires = function(time)
		return os.date("!Expires=%a, %d-%b-%Y %H:%M:%S GMT", time)
	end,
}

function _M:Set(name, value, ...)
	local cookie = {}
	table.insert(cookie, ('%s=%s'):format(name, value))

	for i=1, select('#', ...) do
		local type, argument = select(i, ...)
		if(handlers[type]) then
			local a = handlers[type](argument)
			if(a) then
				table.insert(cookie, a)
			end
		end
	end

	header('Set-Cookie', table.concat(cookie, ';'))
end

function _M:Delete(name)
	return self:Set(name, '', 'expires', 1)
end

return _M
