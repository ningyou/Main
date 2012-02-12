local template = require'template'
local ob = require'ob'
local request = require'request'
local user = require'user'
local sessions = require'sessions'

local post = request._POST

return {
	index = function(user)
		setReturnCode(404)
	end,
	signup = function()
		if post["submit"] then
			local register, err = user:Register(post["name"], post["password"], post["mail"])
			if register then
				ob.Get'Content':write("Success!")
			else
				ob.Get'Content':write(err)
			end
		else
			template:RenderView('signup')
		end
	end,
	login = function()
		if sessions.user_id then
			ob.Get'Content':write("Already logged in")
		elseif post["submit"] then
			local login = user:Login(post["name"], string.SHA256(post["password"]))
			if login then
				ob.Get'Content':write("Success! <br/>")
				sessions:Save(login)
			else
				ob.Get'Content':write("Wrong Username or Password")
			end
		else
			template:RenderView('login')
		end
	end,
}
