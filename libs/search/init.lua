local db = require"db"
local http = require"http"

local _M = {}

function _M.apikey(site)
	local r = db:query("ningyou.apikey", { site = site }):results()()
	return r.key
end

_M.tvrage = require'search.tvrage'
_M.moviedb = require'search.moviedb'

return _M
