return {
	{'^/?$', 'static.lua'},
	{'^/debug', 'debug.lua'},
	{'^/signup', 'user.lua', 'signup'},
	{'^/404', '404.lua'},
	{'^/login', 'user.lua', 'login'},
	{'^/logout', 'user.lua', 'logout'},
	{'^/google', 'user.lua', 'google_oauth_callback'},

	{'^/[a-zA-Z0-9%-]+', 'user.lua'}
}
