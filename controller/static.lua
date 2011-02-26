local template = require'template'

return {
	index = function()
		template:RenderView('default')
	end,
}
