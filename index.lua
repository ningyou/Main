package.path = table.concat({
	'libs/?/init.lua',
	'libs/?.lua',

	'models/?.lua',
	'models/?/init.lua',

	-- To force a trailing ;.
	'',
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

		local customBuffer, kind = routing:Route()
		local content
		if(not kind) then
			ob.Get'Content':write('\n<!-- ', os.clock(), ' seconds', ' | ', collectgarbage'count', ' kB', ' -->')
			content = ob.Get'Content':flush()
		elseif(kind == 'content') then
			content = ob.Get(customBuffer):flush()
		end

		if(kind ~= 'redirect') then
			header('Content-Length', #content)
		end

		header:Generate()
		if(content) then
			echo(
				ob.Get'Header':flush() ..
				content
			)
		else
			echo(ob.Get'Header':flush())
		end
	end,

	function(err)
		echo'<h1>I accidently the page!</h1>'
		echo('<pre>', err:gsub('/.-/ningyou/', ''), '</pre>')
		echo'<h2>Debug stack:</h2>'
		echo('<pre>', debug.traceback():gsub('\t/.-/ningyou/', '\t'), '</pre>')
	end
)
