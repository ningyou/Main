#!/usr/bin/env lua
if(not magnet) then
	local lfs = require'lfs'
	lfs.chdir'..'
end

package.path = table.concat({
	'libs/?/init.lua',
	'libs/?.lua',

	'models/?.lua',
	'models/?/init.lua',
}, ';') .. package.path

local header = require'header'
local routing = require'routing'
local ob = require'ob'
local request = require'request'
local sessions = require'sessions'

xpcall(
	function()
		header:Init()
		request:Init()
		routing:Init(dofile'config/routing.lua')
		sessions:Init()

		local customBuffer = routing:Route()
		local content
		if(customBuffer) then
			content = ob.Get(customBuffer):flush()
		else
			ob.Get'Content':write('\n<!-- ', os.clock(), ' seconds', ' | ', collectgarbage'count', ' kB', ' -->')
			content = ob.Get'Content':flush()
		end

		header('Content-Length', #content)
		header:Generate()

		print(
			ob.Get'Header':flush() ..
			content
		)
	end,

	function(err)
		io.write'Content-Type: text/html\n\n'
		io.write'<h1>I accidently the page!</h1>'
		io.write('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		io.write'<h2>Debug stack:</h2>'
		io.write('<pre>', debug.traceback():gsub('\t/.-/ningyou/', '\t'), '</pre>')
	end
)
