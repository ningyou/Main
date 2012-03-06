return {
	{'^/?$', 'static'},
	{'^/debug', 'debug'},
	{'^/signup', 'user', 'signup'},
	{'^/404', '404'},
	{'^/login', 'user', 'login'},
	{'^/logout', 'user', 'logout'},
	{'^/google', 'user', 'google_oauth_callback'},
	{'^/import', 'user', 'import'},
	{'^/lists', 'user', 'lists'},
	{'^/search', 'user', 'search'},

	{'^/[a-zA-Z0-9%-]+', 'user'}
}
