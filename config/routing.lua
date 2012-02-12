return {
	{'^/?$', 'static.lua'},
	{'^/debug', 'debug.lua'},
	{'^/signup', 'signup.lua'},
	{'^/404', '404.lua'},
	{'^/login', 'login.lua'},

	{'^/[a-zA-Z0-9%-]+', 'user.lua'}
}
