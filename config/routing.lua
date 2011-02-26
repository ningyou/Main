return {
	{'^/?$', 'static.lua'},
	{'^/debug', 'debug.lua'},

	{'^/[a-zA-Z0-9%-]+', 'user.lua'}
}
