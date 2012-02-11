local ob = require'ob'

return {
	index = function()
		ob.Get'Content':write'<h1>404: Not found</h1>'
		ob.Get'Content':write"We had to eat the page you are looking for. It was yummy."

		setReturnCode(404)
	end,
}
