local template = require'template'
local ob = require'ob'
local request = require'request'
local user = require'user'
local sessions = require'sessions'

local post = request._POST
local content = ob.Get'Content'

return {
	index = function(user)
		return 404
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
			local uri = post["referer"] or "/"
			local login = user:Login(post["name"], string.SHA256(post["password"]))
			if login then
				local timeout
				if not post["remember"] then timeout = (os.time() + 7200) end
				sessions:Save(login, timeout)
				content:write("Great success!")
				header("Location", uri)
				setReturnCode(302)
			else
				content:write("Wrong Username or Password")
			end
		else
			template:RenderView('login')
		end
	end,
	logout = function()
		if not sessions.session_id then
			content:write("You are not logged in.")
			header("Location", "/")
			setReturnCode(302)
		else
			sessions:Delete(sessions.session_id)
			content:write("You have logged out.")
			header("Location", "/")
			setReturnCode(302)
		end
	end,
	google_oauth_callback = function()
		content:write("More to come..")
	end,
}
