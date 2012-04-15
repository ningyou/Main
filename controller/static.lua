local controller = require'controller'
local template = require'template'
local sessions = require'sessions'
local user = require'user'

return {
	index = function()
		if(sessions.username) then
			controller:Call('user', nil, sessions.username)
		else
			template:RenderView('default')
		end
	end,
}
