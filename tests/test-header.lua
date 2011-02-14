local header = require'header'
local ob = require'ob'

context('Library: Header', function()
	local buffer = ob.Get('Header')

	test('can generate', function()
		header:Generate()

		local out
		buffer:flush(function(s) out = s end)

		assert_equal(out, 'Content-Type: text/html\n\n')
	end)

	test('can add', function()
		header('Ningyou', 'Doll')
		header:Generate()

		local out
		buffer:flush(function(s) out = s end)

		assert_equal(out, 'Content-Type: text/html\r\nNingyou: Doll\n\n')
	end)
end)
