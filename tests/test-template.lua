local template = require'template'

context('Library: Template', function()
	context('static template', function()
		test('simple', function()
			local input = "<p>Simple</p>"
			local gen = template:Generate(input, true)

			assert_equal(gen, "_O:write[=[<p>Simple</p>]=]")
		end)

		test('simple with newlines', function()
			local input = "<p>Simple</p>\n<p>Simple</p>"
			local gen = template:Generate(input, true)

			assert_equal(gen, "_O:write[=[<p>Simple</p>\n<p>Simple</p>]=]")
		end)

		test('simple non-minor template', function()
			local input = "<p>Simple</p>"
			local gen = template:Generate(input)

			assert_equal(gen, "local ob = require'ob'\nlocal _O = ob.Get'Content'\n_O:write[=[<p>Simple</p>]=]")
		end)
	end)

	context('dynamic template', function()
		context('variable', function()
			test('single', function()
				local input = '{{ var }}'
				local gen = template:Generate(input, true)

				assert_equal(gen, '_O:write(var)')
			end)

			test('double without space', function()
				local input = '{{ var }} {{ var }}'
				local gen = template:Generate(input, true)

				assert_equal(gen, '_O:write(var)\n_O:write[=[ ]=]\n_O:write(var)')
			end)

			test('double with space', function()
				local input = '{{ var }} {{ var }}'
				local gen = template:Generate(input, true)

				assert_equal(gen, '_O:write(var)\n_O:write[=[ ]=]\n_O:write(var)')
			end)

			test('double with several spaces', function()
				local input = '{{ var }}           {{ var }}'
				local gen = template:Generate(input, true)

				assert_equal(gen, '_O:write(var)\n_O:write[=[           ]=]\n_O:write(var)')
			end)
		end)

		context('snippet', function()
			test('single line', function()
				local input = '{% if(true) then end %}'
				local gen = template:Generate(input, true)

				assert_equal(gen, 'if(true) then end')
			end)

			test('multi line', function()
				local input = '{% if(true) then\nend %}'
				local gen = template:Generate(input, true)

				assert_equal(gen, 'if(true) then\nend')
			end)

			test('multi line with html', function()
				local input = '{% if(true) then\nlocal a = "test"\n %}\n<p>Clearly</p>\n{% print(a)\nend %}'
				local gen = template:Generate(input, true)

				assert_equal(gen, 'if(true) then\nlocal a = "test"\n_O:write[=[\n<p>Clearly</p>\n]=]\nprint(a)\nend')
			end)
		end)

		context('combined', function()
			test('multi line with html and variable', function()
				local input = '{% if(true) then\nlocal a = "test"\n %}\n{{ a }}\n{% print(a)\nend %}'
				local gen = template:Generate(input, true)

				assert_equal(gen, 'if(true) then\nlocal a = "test"\n_O:write[=[\n]=]\n_O:write(a)\n_O:write[=[\n]=]\nprint(a)\nend')
			end)
		end)

		context('javascript', function()
			test('simple jQuery', function()
				local input = [[
					$('#login-modal').on('shown', function () {
						$("#login :input:first").focus();
					})
				]]

				local gen = template:Generate(input, true)
				assert_equal(gen, [==[
_O:write[=[					$('#login-modal').on('shown', function () ]=]
_O:write[=[{$("#login :input:first").focus();}]=]
_O:write[=[)
				]=]]==])
			end)
		end)
	end)
end)
