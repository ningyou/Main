local template = require'template'
local ob = require'ob'
local request = require'request'
local user = require'user'
local sessions = require'sessions'

local post = request._POST
local content = ob.Get'Content'

return {
	index = function(user)
		setReturnCode(404)
	end,
	signup = function()
		if post["submit"] then
			local register, err = user:Register(post["name"], post["password"], post["mail"])
			if register then
				content:write("Success!")
			else
				content:write(err)
			end
		else
			template:RenderView('signup')
		end
	end,
	login = function()
		if sessions.user_id then
			content:write("Already logged in as " .. user:Name(sessions.user_id))
		elseif post["submit"] then
			local login = user:Login(post["name"], string.SHA256(post["password"]))
			if login then
				content:write("Success! <br/>")
				sessions:Save(login)
			else
				content:write("Wrong Username or Password")
			end
		else
			template:RenderView('login')
		end
	end,
	logout = function()
		if not sessions.user_id then
			content:write("You are not logged in.")
		else
			sessions:Delete(sessions.sessions_id)
			content:write("You have logged out.")
		end
	end,
}
