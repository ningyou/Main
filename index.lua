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
local request = require'request'
local sessions = require'sessions'

xpcall(
	function()
		request:Init()
		routing:Init(dofile'config/routing.lua')
		sessions:Init()

		local customBuffer, kind = routing:Route()
		local content
		if(not kind) then
			local after = clock()
			local diff = after.seconds * 1e9 + after.nanoseconds - (before.seconds * 1e9 + before.nanoseconds)

			ob.Get'Content':write('\n<!-- ', diff / 1e6, ' ms', ' | ', collectgarbage'count', ' kB', ' -->')
			content = ob.Get'Content':flush()
		elseif(kind == 'content') then
			content = ob.Get(customBuffer):flush()
		end

		if(kind ~= 'redirect') then
			header('Content-Length', tostring(#content))
		end

		if(content) then
			echo(
				content
			)
		end
	end,

	function(err)
		echo'<h1>I accidently the page!</h1>'
		echo('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		echo'<h2>Debug stack:</h2>'
		echo('<pre>', debug.traceback():gsub('\t/.-/ningyou/', '\t'), '</pre>')
	end
)
