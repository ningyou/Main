local _M = {}

local buffers = {}
local bufferMetatable = {
	__index = {
		write = function(self, ...)
			for i=1, select('#', ...) do
				table.insert(self.__buffer, (select(i, ...)))
			end
		end,

		flush = function(self, custom)
			(io.write or custom) (table.concat(self.__buffer))
			self:reset()
		end,

		reset = function(self)
			self.__buffer = {}
		end,
	}
}

function _M.Create(name)
	if(buffers[name]) then return nil end

	local mt = setmetatable({__buffer = {}}, bufferMetatable)
	buffers[name] = mt
	return mt
end

function _M.Get(name)
	return buffers[name] or _M.Create(name)
end

return _M
