return {
	{'^/?$', 'static'},
	{'^/debug', 'debug'},
	{'^/signup', 'user', 'signup'},
	{'^/404', '404'},
	{'^/login', 'user', 'login'},
	{'^/logout', 'user', 'logout'},
	{'^/google', 'user', 'google_oauth_callback'},
	{'^/import', 'import', 'import'},
	{'^/lists', 'user', 'lists'},
	{'^/search', 'search', 'search'},
	{'^/add', 'user', 'add'},
	{'^/del', 'user', 'del'},
	{'^/api', 'api', },

	{'^/[a-zA-Z0-9%-]+', 'user'}
}
