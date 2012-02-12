local template = require'template'

return {
	index = function()
		template:RenderView('login')
	end,
}
