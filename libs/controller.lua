local _M = {
	__controllers = {}
}

function _M:Call(name, handler, ...)
	-- Lazy load controllers.
	local controller
	if(not self:IsLoaded(name)) then
		controller = self:Load(name)
	else
		controller = self.__controllers[name]
	end

	-- Assume `index` if no handler is defined.
	if(not handler) then
		handler = 'index'
	end

	if(not controller[handler]) then
		error(('Attempted to call non-existent handler `%s` on `%s`.'):format(name, handler), 2)
	end

	return controller[handler](...)
end

function _M:IsLoaded(name)
	return self.__controllers[name] and true
end

function _M:Load(name)
	local path = string.format('controller/%s.lua', name)
	local contFunc, err = loadfile(path)
	if(not contFunc) then
		error(err)
	end

	local success, controller = pcall(contFunc)
	if(not success) then
		error(controller, 0)
	end

	self.__controllers[name] = controller
	return controller
end

return _M
