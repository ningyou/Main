local header = require'header'
local ob = require'ob'

context('Library: Header', function()
	local buffer = ob.Get('Header')

	test('can generate', function()
		header:Init()
		header:Generate()

		assert_equal(buffer:flush(), 'Content-Type: text/html\n\n')
	end)

	test('can add', function()
		header:Init()
		header('Ningyou', 'Doll')
		header:Generate()

		assert_equal(buffer:flush(), 'Content-Type: text/html\r\nNingyou: Doll\n\n')
	end)
end)
