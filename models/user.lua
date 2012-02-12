local db = require"db"
local _M = {}

function _M:ValidateMail(mail)
	-- STRICT AS HELL!
	return not not mail:match('.+@.+%..+')
end

function _M:ValidateName(name)
	-- Check for existing users.
	local len = #name
	return len > 0 and len < 31 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

function _M:Register(name, password, mail)
	if self:ValidateMail(mail) and self:ValidateName(name) and password ~= nil then
		if db:find_one("ningyou.users", { name = name }) then return nil, "User Exists" end
		if db:find_one("ningyou.users", { mail = mail }) then return nil, "Mail Exists" end

		db:insert("ningyou.users", { name = name:lower(), mail = mail:lower(), password = string.SHA256(password) })
		return name
	end
end

function _M:Login(login, password)
	if(not password) then return end

	local field
	if(self:ValidateMail(login)) then
		field = "mail"
	elseif(self:ValidateName(login)) then
		field = "name"
	else
		return
	end

	local r = db:find_one("ningyou.users", { [field] = login:lower() })
	if r then
		if password == r.password then
			return tostring(r._id)
		else
			return
		end
	end
end

function _M:Name(user_id)
	local r = db:find_one("ningyou.users", { _id = mongo.ObjectId(user_id) })

	if r then
		return r.name
	else
		return
	end
end

function _M:ID(name)
	local r = db:find_one("ningyou.users", { name = name:lower() })

	if r then
		return tostring(r._id)
	else
		return
	end
end

return _M
