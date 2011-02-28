local s = require'sessions'

context('Library: Sessions', function()
	test('can save and get session id\'s', function()
		local id = "31337"
		local oid = s:save(id)
		assert_not_nil(oid)
		assert_equal(s:get(oid), id)
	end)
end)
