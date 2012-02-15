local template = require'template'
local sessions = require'sessions'
local user = require'user'

return {
	index = function()
		local default_env = {
			["user_id"] = sessions.user_id,
			["user"] = user:Name(sessions.user_id),
			["uri"] = "http://" .. getEnv()["Host"] .. (getEnv()['Path-Info'] or "/")
		}
		template:RenderView('default', nil, default_env)
	end,
}
