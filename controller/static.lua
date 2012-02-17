local controller = require'controller'
local template = require'template'
local sessions = require'sessions'
local user = require'user'

return {
	index = function()
		if(sessions.user_id) then
			controller:Call('user', nil, user:Name(sessions.user_id))
		else
			local default_env = {
				["uri"] = "http://" .. getEnv()["Host"] .. (getEnv()['Path-Info'] or "/")
			}
			template:RenderView('default', nil, default_env)
		end
	end,
}
