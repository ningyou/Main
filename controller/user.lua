local template = require'template'
local ob = require'ob'
local user = require'user'
local sessions = require'sessions'
local zlib = require'zlib'

local content = ob.Get'Content'

return {
	index = function(name, second)
		print(second)
		local user_id = user:ID(name)
		if not user_id then return 404 end

		local user_env = {
			logged_user = user:Name(sessions.user_id),
			logged_user_id = sessions.user_id,
			user = user:Name(user_id),
			user_id = user_id,
		}

		template:RenderView('user', nil, user_env)
	end,
	signup = function()
		if _POST["submit"] then
			local register, err = user:Register(_POST["name"], _POST["password"], _POST["mail"])
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
		elseif _POST["submit"] then
			local uri = _POST["referer"] or "http://" .. getEnv()["Host"] .. "/"
			local login = user:Login(_POST["name"], string.SHA256(_POST["password"]))
			if login then
				local timeout
				if not _POST["remember"] then timeout = (os.time() + 7200) end
				sessions:Save(login, timeout)
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
			header("Location", "/")
			setReturnCode(302)
		else
			sessions:Delete(sessions.session_id)
			header("Location", "/")
			setReturnCode(302)
		end
	end,
	google_oauth_callback = function()
		content:write("More to come..")
	end,
	import = function()
		local user_env = {
			logged_user = user:Name(sessions.user_id),
			logged_user_id = sessions.user_id,
			user = user:Name(user_id),
			user_id = user_id,
		}

		if _POST["import_file"] and _POST["site"] == "mal" then
			local xml = zlib.inflate() (_POST["import_file"][2])

			echo(tostring(xml))
		else
			template:RenderView('import', nil, user_env)
		end
	end,
}
