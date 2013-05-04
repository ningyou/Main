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
		return nil, 'Invalid username'
	end

	local len = #name
	return len > 0 and len < 31 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

function _M:Register(name, password, mail)
	if self:ValidateMail(mail) and self:ValidateName(name) and password then
		local query = "select 1 from ningyou_users where lower(name) = lower('%s') or lower(mail) = lower('%s') limit 1"
		local res = _DB:execute(query:format(name, mail))
		if res:numrows() > 0 then return nil, 'User Exists' end

		local query = "insert into ningyou_users (name, mail, password) values ('%s', '%s', '%s')"
		_DB:execute(query:format(name, mail:lower(), string.SHA256(password)))
		return name
	end
end

function _M:Login(login, password)
	if(not password) then return end

	local field
	if(self:ValidateMail(login)) then
		field = 'mail'
	else
		field = 'name'
	end

	local query = "select id, name, password from ningyou_users where LOWER(%s) = LOWER('%s') limit 1"
	local res = _DB:execute(query:format(field, login))
	if not (res:numrows() > 0) then return end

	local user_id, name, res_password = res:fetch()
	if password ~= res_password then return end

	return name, user_id
end

function _M:Exists(name)
	local query = "select name, id from ningyou_users where lower(name) = lower('%s') limit 1"
	local res = _DB:execute(query:format(name))

	if res:numrows() > 0  then return res:fetch() end
end

return _M
