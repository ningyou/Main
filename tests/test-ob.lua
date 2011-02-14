local ob = require'ob'

context('Library: Output buffer', function()
	local buffer
	before(function()
		if(not buffer) then
			buffer = ob.Create('Test 1')
		end
	end)

	test('can create', function()
		assert_not_nil(buffer)
	end)

	test('are equal', function()
		assert_equal(buffer, ob.Get('Test 1'))
	end)

	test('can reset', function()
		buffer:write('test')
		buffer:reset()

		assert_nil(next(buffer.__buffer))
	end)

	test('can single write', function()
		buffer:write('test')

		local out
		buffer:flush(function(s) out = s end)

		assert_equal(out, 'test')
	end)

	test('can multi write', function()
		buffer:write('this', 'is', 'a', 'test')

		local out
		buffer:flush(function(s) out = s end)

		assert_equal(out, 'thisisatest')
	end)
end)
