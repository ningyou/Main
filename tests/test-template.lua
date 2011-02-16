local template = require'template'


context('Library: Template', function()
	context('static template', function()
		test('simple', function()
			local input = "<p>Simple</p>"
			local gen = template:Generate(input, _G)

			assert_equal(gen, "io.write[=[<p>Simple</p>]=]")
		end)

		test('simple with newlines', function()
			local input = "<p>Simple</p>\n<p>Simple</p>"
			local gen = template:Generate(input, _G)

			assert_equal(gen, "io.write[=[<p>Simple</p>\n<p>Simple</p>]=]")
		end)
	end)

	context('dynamic template', function()
		context('variable', function()
			test('single', function()
				local input = '{{ var }}'
				local gen = template:Generate(input)

				assert_equal(gen, 'io.write(var)')
			end)

			test('double without space', function()
				local input = '{{ var }} {{ var }}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'io.write(var)\nio.write(var)')
			end)

			test('double with space', function()
				local input = '{{ var }} {{ var }}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'io.write(var)\nio.write(var)')
			end)

			test('double with several spaces', function()
				local input = '{{ var }}           {{ var }}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'io.write(var)\nio.write(var)')
			end)
		end)

		context('snippet', function()
			test('single line', function()
				local input = '{% if(true) then end %}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'if(true) then end')
			end)

			test('multi line', function()
				local input = '{% if(true) then\nend %}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'if(true) then\nend')
			end)

			test('multi line with html', function()
				local input = '{% if(true) then\nlocal a = "test"\n %}\n<p>Clearly</p>\n{% print(a)\nend %}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'if(true) then\nlocal a = "test"\nio.write[=[<p>Clearly</p>]=]\nprint(a)\nend')
			end)
		end)

		context('combined', function()
			test('multi line with html and variable', function()
				local input = '{% if(true) then\nlocal a = "test"\n %}\n{{ a }}\n{% print(a)\nend %}'
				local gen = template:Generate(input, setmetatable({var = 'variable'}, {__index = _G}))

				assert_equal(gen, 'if(true) then\nlocal a = "test"\nio.write(a)\nprint(a)\nend')
			end)
		end)
	end)
end)
