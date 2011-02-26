local user = require'models.user'

context('Model: User', function()
	context('mail validation', function()
		test('mail #1', function()
			assert_true(user:ValidateMail('test@example.com'))
		end)

		test('mail #2', function()
			assert_true(user:ValidateMail('test+test@example.com'))
		end)

		test('mail #3', function()
			assert_true(user:ValidateMail('test\\@test@example.com'))
		end)

		test('mail #4', function()
			assert_true(user:ValidateMail('"Abc\\@def"@example.com'))
		end)

		test('mail #5', function()
			assert_true(user:ValidateMail('"Joe\\Blow"@example.com'))
		end)

		test('mail #6', function()
			assert_true(user:ValidateMail('"Abc@def"@example.com'))
		end)

		test('mail #7', function()
			assert_true(user:ValidateMail('!def!xyz%abc@example.com'))
		end)

		test('mail #8', function()
			assert_false(user:ValidateMail('@example.com'))
		end)

		test('mail #9', function()
			assert_false(user:ValidateMail('mail@example'))
		end)

		test('mail #10', function()
			assert_false(user:ValidateMail('mail'))
		end)

		test('mail #11', function()
			assert_false(user:ValidateMail('mail@.com'))
		end)

		test('mail #12', function()
			assert_false(user:ValidateMail(''))
		end)
	end)

	context('user name validation', function()
		test('name #1', function()
			assert_true(user:ValidateName('haste'))
		end)

		test('name #2', function()
			assert_true(user:ValidateName('haste134'))
		end)

		test('name #3', function()
			assert_true(user:ValidateName('h'))
		end)

		test('name #4', function()
			assert_false(user:ValidateName(' '))
		end)

		test('name #5', function()
			assert_false(user:ValidateName(''))
		end)

		test('name #6', function()
			assert_false(user:ValidateName('$#ha='))
		end)

		test('name #7', function()
			assert_false(user:ValidateName('-haste'))
		end)
	end)
end)
