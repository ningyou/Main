package.path = table.concat({
	'../libs/?/init.lua',
	'../libs/?.lua',

	'../models/?.lua',
	'../models/?/init.lua',

	'../?.lua',
	'../?/init.lua',
}, ';') .. package.path
