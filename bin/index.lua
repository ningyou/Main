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

xpcall(
	function()
		header:Init()
		routing:Init(dofile'config/routing.lua')

		routing:Route()

		ob.Get'Content':write('\n<!-- ', os.clock(), ' seconds', ' | ', collectgarbage'count', ' kB', ' -->')
		local content = ob.Get'Content':flush()

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
