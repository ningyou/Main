local ob = require'ob'
local header = require'header'

return {
	index = function()
		ob.Get'Content':write'<h1>404: Not found</h1>'
		ob.Get'Content':write"We had to eat the page you are looking for. It was yummy."

		header('Status', '404')
	end,
}
