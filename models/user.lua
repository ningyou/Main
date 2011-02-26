local _M = {}

function _M:ValidateMail(mail)
	-- STRICT AS HELL!
	return not not mail:match('.+@.+%..+')
end

function _M:ValidateName(name)
	return #name > 0 and not name:match('^%-') and not name:match('[^a-zA-Z0-9%-]')
end

return _M
