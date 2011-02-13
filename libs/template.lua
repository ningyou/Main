local _M = {}

local tags = {}
local template = {}

function _M:RegisterTemplate(name, html)
	template[name] = html
end

function _M:RegisterTag(tag, func, template)
	tags[tag] = {
		func = func,
		template = template,
	}
end

function _M:RenderTags(html)
	return html:gsub("<lua:(%S+)%s*(.-)/>", function(tag, args)
		local a = {}
		local out

		if tags[tag] then
			-- Parse arguments
			for k, v in args:gmatch("%s*(.-)=%\"(.-)%\"") do
				a[k] = v
			end

			if tags[tag].template and template[tags[tag].template] and type(tags[tag].func) == "table" then
				out = self:RenderTemplate(tags[tag].template, tags[tag].func, a)
			else
				out = tags[tag].func(a)
			end
		end

		return out
	end)
end

function _M:RenderTemplate(name, func, args)
	local t = template[name]
	for i,v in pairs(func) do
		if args[v] then
			t = t:gsub(v, args[v])
		end
	end

	return t
end

return _M
