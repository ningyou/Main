local db = require"db"

local _, hmacFile = pcall(io.open, 'config/hmac')
local hmackey
if(hmacFile) then
	hmackey = hmacFile:read'*a'
	hmacFile:close()
end

local _M = {}

function _M:ValidateMail(mail)
	-- STRICT AS HELL!
	local r = db:find_one("ningyou.users", { mail = mail })
	if r then return end
	return not not mail:match('.+@.+%..+')
end

function _M:ValidateName(name)
	-- Check for existing users.
	local r = db:find_one("ningyou.users", { name = name })
	if r then return end

	local len = #name
	return len > 0 and len < 31 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

function _M:Register(name, password, mail)
	if self:ValidateMail(mail) and self:ValidateName(name) and password ~= nil then
		local user_id = db:find_one("ningyou.counters", { _id = "userid" }).c + 1
		password = string.SHA256(password)
		
		db:insert("ningyou.users", { name = name:lower(), mail = mail:lower(), password = password })
		db:update("ningyou.counters", { _id = "userId" }, { c = id })
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
		password = string.SHA256(password)
		if password == r.password then
			return r.user_id
		else
			return
		end
	end
end

function _M:IDToName(user_id)
	local r = db:find_one("ningyou.users", { user_id = user_id })

	if r then
		return r.name
	else
		return
	end
end

function _M:NameToID(name)
	local r = db:find_one("ningyou.users", { name = name:lower() })

	if r then
		return r.user_id
	else
		return
	end
end

return _M
