local controller = require'controller'

local _M = {}

function _M:Path(path)
	local pathInfo = (path or getEnv()['Path-Info']) or '/'
	local split = {}
	for str in pathInfo:gmatch'[^/]+' do
		table.insert(split, str)
	end

	return pathInfo, split
end

local routes
function _M:Route(path)
	local pathInfo, pathSplit = self:Path(path)
	if(not pathInfo) then return end

	for i=1, #routes do
		local ptrn, name, handler = unpack(routes[i])
		if(pathInfo:match(ptrn)) then
			if(not handler) then handler = 'index' end

			-- pwetty!
			local redirect, silent = controller:Call(name, handler, unpack(pathSplit))
			if(redirect) then
				return self:Route('/' .. redirect)
			end

			return nil, silent
		end
	end

	-- Return error/404
	return controller:Call(404, nil, unpack(pathSplit))
end

function _M:Init(tbl)
	routes = {}

	for _, route in ipairs(tbl) do
		table.insert(routes, {unpack(route)})
	end
end

return _M
