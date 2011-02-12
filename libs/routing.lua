local ob = require'ob'

local routes = {}

local _M = {}

function _M:Path()
	local pathInfo = os.getenv'PATH_INFO'
	if(pathInfo) then
		local split = {}
		for str in path:gmatch'[^/]+' do
			table.insert(split, str)
		end

		return pathInfo, split
	end
end

function _M:Route()
	local pathInfo, pathSplit = self:Path()

	for i=1, #routes do
		local ptrn, dst = unpack(routes[i])
		if(pathInfo:match(ptrn)) then
			ob.Get'Content':write(unpack(pathSplit))
		end
	end
end

function _M:Register(ptrn, dst)
	table.insert(routes, {ptrn, dst})
end

return _M
