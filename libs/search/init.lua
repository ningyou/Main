local db = require"db"
local http = require"http"

local _M = {}

function _M.apikey(site)
	local q = db:query("ningyou.apikey", { site = site })
	local r = q:results()()
	return r.key
end

_M.tvrage = require'search.tvrage'
_M.moviedb = require'search.moviedb'

return _M
