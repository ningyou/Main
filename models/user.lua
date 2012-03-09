local _M = {}

local blacklist = {
	'about', 'account', 'add', 'admin', 'adminstrator', 'api', 'app', 'apps',
	'auth', 'blog', 'browserid', 'cache', 'changelog', 'compare', 'config',
	'connect', 'create', 'delete', 'edit', 'explore', 'export', 'faq',
	'favorites', 'feeds', 'friends', 'help', 'history', 'home', 'info', 'lists',
	'login', 'logout', 'logs', 'news', 'oauth', 'openid', 'popular', 'profile',
	'remove', 'rss', 'search', 'settings', 'signup', 'sitemap', 'ssl', 'status',
	'terms', 'tour', 'trends', 'url', 'user', 'wiki', 'xml',

	-- Status codes
	'404',
}

local isBlacklisted = function(name)
	name = name:lower()

	for i=1, #blacklist do
		if(name == blacklist[i]) then
			return true
		end
	end
end

function _M:ValidateMail(mail)
	-- STRICT AS HELL!
	return not not mail:match('.+@.+%..+')
end

function _M:ValidateName(name)
	if(isBlacklisted(name)) then
		return nil, "Invalid username"
	end

	local len = #name
	return len > 0 and len < 31 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

function _M:Register(name, password, mail)
	if self:ValidateMail(mail) and self:ValidateName(name) and password ~= nil then
		if _DB:find_one("ningyou.users", { name_lower = name:lower() }) then return nil, "User Exists" end
		if _DB:find_one("ningyou.users", { mail = mail:lower() }) then return nil, "Mail Exists" end

		_DB:insert("ningyou.users", { name = name, name_lower = name:lower(), mail = mail:lower(), password = string.SHA256(password) })
		_DB:ensure_index("ningyou.users", { name_lower = 1, mail = 1 }, 1)
		return name
	end
end

function _M:Login(login, password)
	if(not password) then return end

	local field
	if(self:ValidateMail(login)) then
		field = "mail"
	else
		field = "name_lower"
	end

	local r = _DB:find_one("ningyou.users", { [field] = login:lower() })
	if r then
		if password == r.password then
			return tostring(r._id)
		else
			return
		end
	end
end

function _M:Name(user_id)
	local r = _DB:find_one("ningyou.users", { _id = mongo.ObjectId(user_id) })

	if r then return r.name end
end

function _M:ID(name)
	local r = _DB:find_one("ningyou.users", { name_lower = name:lower() })

	if r then return tostring(r._id) end
end

return _M
