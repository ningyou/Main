local _M = {}

function _M:unnest(array, list_id)
	local out = {}
	local query = 'select unnest(ningyou_lists.%s) from ningyou_lists where id = %d'
	local res = _DB:execute(query:format(array, list_id))
	local coltype = res:getcoltypes()[1]
	for i = 1, res:numrows() do
		out[i] = tonumber(res:fetch()) or res:fetch()
	end

	return out
end

function _M:get_list_info(id, list)
	local query
	if type(id) == "string" then
		query = 'select list.id, list.name, site, url from ningyou_lists as list, ningyou_list_types as type where type.id = list.type_id and user_id = %d and lower(list.name) = lower(\'%s\')'
	else
		query = 'select list.id, list.name, site, url from ningyou_lists as list, ningyou_list_types as type where type.id = list.type_id and list.id = %d'
	end
	local res, err = _DB:execute(query:format(id, list))
	if err then return print(err) end
	return res:fetch() -- returns id, name, site, url
end

function _M:get_list(list_id, status_id)
	local query = [[
		select show_id as id, episodes, rating, show_title(show_id, lang, site) as title
		from ningyou_lists as l, ningyou_list_data as d, ningyou_list_types as t
		where l.type_id = t.id and d.list_id = l.id and l.id = %d and status_id = %d
		order by title
	]]
	local res, err = _DB:execute(query:format(list_id, status_id))
	if err then return print(err) end
	local out = {}
	for i = 1, res:numrows() do
		out[#out+1] = res:fetch({}, "a")
	end

	return out
end

function _M:results(cursor)
	return function ()
		return cursor:fetch()
	end
end

return _M
