local ob = require'ob'

return {
	index = function()
		-- AMAZING CONTENT
		ob.Get'Content':write'<h1>Landing page!</h1>'
		ob.Get'Content':write'We has a landing page.'
	end,
}
