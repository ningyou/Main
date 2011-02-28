local crypto = require"crypto"
local hmac = require"crypto.hmac"
local db = require"db"
local hmackey = io.open"config/hmac":read"*all":gsub("\n$", "")

local _M = {}

function _M:ValidateMail(mail)
	-- STRICT AS HELL!
	return not not mail:match('.+@.+%..+')
end

function _M:ValidateName(name)
	local len = #name
	return len > 0 and len < 31 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

function _M:Register(name, password, mail)
	if self:ValidateMail(mail) and self:ValidateName(name) and password ~= nil then
		local id = mongo.GenerateID()
		password = hmac.digest("sha256", password, hmackey)

		db:insert("ningyou.users", { _id = mongo.ObjectId(id), name = name:lower(), mail = mail:lower(), password = password })

		return id
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
		-- XXX: Redirect user to invalid username and/or passowrd.
	end

	local r = db:query("ningyou.users", { [field] = login:lower() }):results()()
	if r then
		password = hmac.digest("sha256", password, hmackey)
		if password == r.password then
			return r._id
		else
			-- XXX: Redirect user to invalid username and/or passowrd.
		end
	end
end

return _M
