-- Highly inspired by Jinja. <3 Syntax that doesn't make my eyes bleed.
local _M = {}

-- Just to make our life slightly simpler. Needs to be updated to reflect the
-- magic characters of the types table.
-- / is used as dummy to fetch the results at the end of the template.
local typesString = '%%{/'
local types = {
	-- Variable
	['{'] = function(var)
		return ('_O:write(%s)'):format(var)
	end,

	-- String of Lua code
	['%'] = function(code)
		return code
	end,
}

local replaces = {
	['include'] = function(path)
		local file
		if(path:sub(1,1) == '/') then
			file = io.open(path, 'r')
		else
			file = io.open('views/' .. path)
		end

		return file:read'*a'
	end,
}

local trim = function(s)
	return s:match('^()%s*$') and '' or s:match('^%s*(.*%S)')
end

local handleReplace = function(cmd, data)
	if(replaces[cmd]) then
		return replaces[cmd](data)
	end
end

local pattern = '([^{]*)(%b{})'
--local pattern = '([^{]*){([' .. typesString .. '])%s*(.-)%s*[' .. typesString .. ']-}'

function _M:Generate(templateData, minor)
	templateData = templateData .. '{//}'

	local out
	if(minor) then
		out = {}
	else
		out = {
			"local ob = require'ob'",
			"local _O = ob.Get'Content'"
		}
	end

	-- Slightly lazy solution! :D
	templateData = templateData:gsub('<%%(%w+)%s*([^%%]+) %%>', handleReplace)

	for html, tag in templateData:gmatch(pattern) do
		local identifier = tag:sub(2, 2)
		local code = tag:sub(3, -3)

		-- Strip away spaces between {{}}.
		-- NOTE: We aren't required to actually run this, it just makes the
		-- output slightly easier to unit test. IF it causes issues we can
		-- simply remove it.
		code = trim(code)
		-- Spaces between tags can yield padded lines.
		html = trim(html)

		-- We fetch 0 or more of not {, so it can give is a empty string :(
		if(#html ~= 0) then
			table.insert(out, ('_O:write[=[%s]=]'):format(html))
		end

		-- Prevent our function from blowing if we try do use some undefined
		-- template type.
		local kind = types[identifier]
		if(kind) then
			table.insert(out, kind(code))
		end
	end

	-- Strip out extra newlines here, should be safe...
	return table.concat(out, '\n'):gsub('[\n]+', '\n')
end

function _M:Render(templateData, minor, env)
	local genTemplate = self:Generate(templateData, minor)

	-- Accidently the page if we fail.
	local func, err = loadstring(genTemplate, 'template')
	if(not func) then
		error(err)
	end

	-- We should create a custom env for this.
	setfenv(func, env or _G)
	return func()
end

function _M:RenderView(view, minor, env)
	local template = io.open('views/' .. view .. '.html', 'r')
	local templateData = template:read'*a'
	template:close()

	return self:Render(templateData, minor,  env)
end

return _M
