#!/usr/bin/env lua
package.path = table.concat({
	'libs/?/init.lua',
	'libs/?.lua',

	'models/?.lua',
	'models/?/init.lua',

	-- To force a trailing ;.
	'',
}, ';') .. package.path

local before = clock()
local routing = require'routing'
local ob = require'ob'
local sessions = require'sessions'
local mongo = require"mongo"

-- We probably want to wrap these in some metatable magic to prevent them
-- from being called unnecessary.
_GET = parseGet()
_POST = parsePost()
_DB = mongo.Connection.New()
_DB:connect"localhost"


xpcall(
	function()
		routing:Init(dofile'config/routing.lua')
		sessions:Init()

		local _, silent = routing:Route()
		if(not silent) then
			local after = clock()
			local diff = after.seconds * 1e9 + after.nanoseconds - (before.seconds * 1e9 + before.nanoseconds)
			ob.Get'Content':write('\n<!-- ', diff / 1e6, ' ms', ' | ', collectgarbage'count', ' kB', ' -->')
		end

		echo(ob.Get'Content':flush())
	end,

	function(err)
		echo'<h1>I accidently the page!</h1>'
		echo('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		echo'<h2>Debug stack:</h2>'
		echo('<pre>', debug.traceback():gsub('\t/.-/ningyou/', '\t'), '</pre>')
	end
)
