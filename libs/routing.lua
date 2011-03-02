local ob = require'ob'

local _M = {}

function _M:Path()
	local pathInfo = os.getenv'PATH_INFO' or os.getenv'SCRIPT_NAME' or os.getenv'SCRIPT_URL'
	if(pathInfo) then
		local split = {}
		for str in pathInfo:gmatch'[^/]+' do
			table.insert(split, str)
		end

		return pathInfo, split
	end
end

local routes
function _M:Route()
	local pathInfo, pathSplit = self:Path()
	if(not pathInfo) then return end

	for i=1, #routes do
		local ptrn, controller, handler = unpack(routes[i])
		if(pathInfo:match(ptrn)) then
			if(not handler) then handler = 'index' end

			-- pwetty!
			return dofile('controller/' .. controller)[handler](unpack(pathSplit))
		end
	end

	return dofile'controller/404.lua'.index(unpack(pathSplit))
end

function _M:Init(tbl)
	routes = {}

	for _, route in ipairs(tbl) do
		table.insert(routes, {unpack(route)})
	end
end

return _M
