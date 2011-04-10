return {
	{'^/?$', 'static.lua'},
	{'^/debug', 'debug.lua'},
	{'^/signup', 'signup.lua'},
	{'^/404', '404.lua'},

	{'^/[a-zA-Z0-9%-]+', 'user.lua'}
}
