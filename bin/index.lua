#!/usr/bin/env lua
local lfs = require'lfs'
lfs.chdir'..'

package.path = 'libs/?/init.lua;libs/?.lua;?.lua;init/?/.lua' .. package.path

local header = require'header'
local routing = require'routing'
local ob = require'ob'

for _, route in ipairs(dofile'config/routing.lua') do
	routing:Register(route[1], route[2], route[3])
end

xpcall(
	function()
		routing:Route()

		header:Generate()
		ob.Get'Header':flush()
		ob.Get'Content':flush()

		io.write('<pre>', os.clock(), ' seconds\n', collectgarbage'count', ' kB\n', '</pre>')
	end,

	function(err)
		io.write'Content-Type: text/html\n\n'
		io.write'<h1>I accidently the page!</h1>'
		io.write('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		io.write'<h2>Debug stack:</h2>'
		io.write('<pre>', debug.traceback():gsub('\t/.-/ningyou/', '\t'), '</pre>')
	end
)
