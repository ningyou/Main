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
		local ptrn, controller, handler = unpack(routes[i])
		if(pathInfo:match(ptrn)) then
			if(not handler) then handler = 'index' end

			-- pwetty!
			return dofile('../controller/' .. controller)[handler](unpack(pathSplit))
		end
	end
end

function _M:Register(ptrn, controller, handler)
	table.insert(routes, {ptrn, controller, handler})
end

return _M
