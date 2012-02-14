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
				local timeout
				if not post["remember"] then timeout = (os.time() + 7200) end
				content:write("Great success!")
				sessions:Save(login, timeout)
				header("refresh", "1;/")
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
			header("refresh", "1;/")
		else
			sessions:Delete(sessions.sessions_id)
			content:write("You have logged out.")
			header("refresh", "1;/")
		end
	end,
	google_oauth_callback = function()
		content:write("More to come..")
	end,
}
