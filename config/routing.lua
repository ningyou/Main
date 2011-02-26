return {
	{'^/?$', 'static.lua'},
	{'^/debug', 'debug.lua'},
	{'^/signup', 'signup.lua'},

	{'^/[a-zA-Z0-9%-]+', 'user.lua'}
}
