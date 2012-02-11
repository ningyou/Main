package.path = table.concat({
	'libs/?/init.lua',
	'libs/?.lua',

	'models/?.lua',
	'models/?/init.lua',

	-- To force a trailing ;.
	'',
}, ';') .. package.path

local routing = require'routing'
local ob = require'ob'
local request = require'request'

xpcall(
	function()
		request:Init()
		routing:Init(dofile'config/routing.lua')

		local customBuffer, kind = routing:Route()
		local content
		if(not kind) then
			ob.Get'Content':write('\n<!-- ', os.clock(), ' seconds', ' | ', collectgarbage'count', ' kB', ' -->')
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
