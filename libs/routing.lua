local ob = require'ob'

local routes = {}

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

function _M:Route()
	local pathInfo, pathSplit = self:Path()
	if(not pathInfo) then return end

	for i=1, #routes do
		local ptrn, dst = unpack(routes[i])
		if(pathInfo:match(ptrn)) then
			return dst(unpack(pathSplit))
		end
	end
end

function _M:Register(ptrn, dst)
	table.insert(routes, {ptrn, dst})
end

return _M
