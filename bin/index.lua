#!/usr/bin/env lua
package.path = '../libs/?/init.lua;../libs/?.lua;?.lua;init/?/.lua' .. package.path

local header = require'header'
local routing = require'routing'
local ob = require'ob'

xpcall(
	function()
		routing:Route()

		-- AMAZING CONTENT
		ob.Get'Content':write'<h1>Landing page!</h1>'
		ob.Get'Content':write'We has a landing page.'

		header:Generate()
		ob.Get'Header':flush()
		ob.Get'Content':flush()

		io.write('<pre>', os.clock(), ' seconds\n', collectgarbage'count', ' kB\n', '</pre>')
	end,

	function(err)
		io.write'Content-Type: text/html\n\n'
		io.write'<h1>I accidently the page!</h1>'
		io.write('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		io.write'<h2>Debug stack:<ningyou'
		io.write('<pre>', debug.traceback():gsub('\t/.-/dump/', '\t'), '</pre>')
	end
)
