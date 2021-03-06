function topalert(alerttxt)
{
	var top_alert = $('#top-alert');
	top_alert.empty().append(alerttxt);
	var alerttimer = window.setTimeout(function () 
	{
		top_alert.click();
	}, 3000);
	top_alert.animate({height: top_alert.css('line-height') || '50px'}, 200).click(function ()
	{
		window.clearTimeout(alerttimer);
		top_alert.animate({height: '0'}, 1000);
	});
}

$('#login-modal').on('shown', function () {
	$("#login :input:first").focus();
})

$('#search').submit(function(event) {
	event.preventDefault()
	var searchType = $('#searchtype').val()
	$.ajax({
		type: "POST",
		url: "/search/"+searchType,
		data: $("#search").serializeArray(),
	}).done(function(data){
		$('#searchbox').val('');
		$('#result').empty().append(data);
	});
})

// Progress click.
$('table > tbody > tr > td:last-child > a:nth-child(2)').click(function()
{
	var table = $(this).closest('table');
	var tr = $(this).closest('tr');
	var id = tr.data('id');
	var title = tr.data('title');
	var ep = $(this).parent().find('a:first').html().split('/')[0] | 0;
	var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
	var status = table.find('th').data('status') | 0;
	var status_arr = JSON.parse($('body').data('status'));
	var statuschange = false;
	var refresh = table.find('thead > tr > th > div > a:first-child')
	ep++;
	
	if(total) {
		if(ep >= total) {
			ep == total;
			status = 2;
			statuschange = true;
		}
	} else {
		total = "?";
	}
	
	if(!(status == 1 || status == 2)) {
		status = 1;
		statuschange = true;
	}

	$(this).parent().find('a:first').empty().append(ep+'/'+total);
	if(this.request) { clearTimeout(this.request) }
	this.request = setTimeout(function() {
	$.ajax({
		type: "POST",
		url: "/add/episode",
			data: {
				"show_id" : id,
				"episodes" : ep,
				"list_id" : $('body').data('list_id'),
				"user_id" : $('body').data('logged_user_id'),
				"status_id" : status,
				"statuschange" : statuschange,
			}
		}).done(function()
		{
			if(statuschange)
			{
				topalert(title+': Status set to '+status_arr[status-1]);
				refresh.show()
			}
		});
	}, 500)
	return false;
});

$('table:not([id]) > tbody > tr > td:last-child > a:first-child').click(function()
{
	var table = $(this).parent()
	var ep = $(this).html().split('/')[0];
	$(this).hide();
	table.find('a:last').hide()
	table.find('input').show('fast').val(ep).select();
	return false;
});

$('table > tbody > tr > td:last-child > input').keyup(function(event)
{
	var table = $(this).closest('table');
	var tr = $(this).closest('tr');
	var id = tr.data('id');
	var title = tr.data('title');
	var statuschange = false;
	if(event.keyCode == 13) {
		var ep = $(this).val() | 0;
		var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
		var status = table.find('th').data('status') | 0;
		var status_arr = JSON.parse($('body').data('status'));
		var refresh = table.find('thead > tr > th > div > a:first-child')

		if(total) {
			if(ep >= total) {
				ep = total;
				status = 2;
				statuschange = true;
			}
		} else {
			total = "?";
		}

		if(!(status == 1 || status == 2)) {
			status = 1;
			statuschange = true;
		}

		if(ep < 0) { ep = 0;}
		
		$(this).hide().focusout();
		$(this).parent().find('a:first').empty().append(ep+'/'+total);
		$.ajax({
			type: "POST",
			url: "/add/episode",
			data: {
				"show_id" : id,
				"episodes" : ep,
				"list_id" : $('body').data('list_id'),
				"user_id" : $('body').data('logged_user_id'),
				"status_id" : status,
				"statuschange" : statuschange,
			}
		}).done(function()
		{
			if(statuschange)
			{
				topalert(title+': Status set to '+status_arr[status-1]);
				refresh.show();
			}
		});
	}
	if(event.keyCode == 27) {
		$(this).hide().focusout();
	}
});

$('table > tbody > tr > td:last-child > input').focusout(function()
{
	$(this).hide().parent().find('a').show()
});

$('table > thead > tr > th > div > a:last-child').click(function()
{
	var table = $(this).closest('table');
	table.find('div[data-edit]').toggle();
	table.find('small').toggle();
	return false;
});

$('table > thead > tr > th > div > a:first-child').click(function()
{
	location.reload();
	return false;
});

$('table > tbody > tr > td > div > select').change(function()
{
	$(this).closest('table').find('thead > tr > th > div > a:first-child').show();
	var id = $(this).closest('tr').data('id');
	var ep = $(this).closest('tr').find('td:last-child').find('a:first').html().split('/')[0] | 0;
	var title = $(this).closest('tr').data('title');
	var status = $(this).val();
	var status_arr = JSON.parse($('body').data('status'));
	var statuschange = true;
	$.ajax({
		type: "POST",
		url: "/add/episode",
		data: {
			"show_id" : id,
			"episodes" : ep,
			"list_id" : $('body').data('list_id'),
			"user_id" : $('body').data('logged_user_id'),
			"status_id" : status,
			"statuschange" : statuschange,
		}
	}).done(function()
	{
		topalert(title+': Status set to '+status_arr[status-1]);
	});
});

$('table > tbody > tr > td > div > a').click(function()
{
	var tr = $(this).closest('tr');
	var id = tr.data('id');
	$.ajax({
		type: "POST",
		url: "/del/show",
		data: {
			"id" : id,
			"list_id" : $('body').data("list_id"),
			"user_id" : $('body').data("logged_user_id"),
		}
	});
	tr.remove();
	return false;
});

$('table:not([id]) > tbody > tr > td:first-child').mouseover(function () {
	if($('body').data('user') == $('body').data('logged_user')) {
		$(this).css('cursor', 'pointer');
	}
});

$('table:not([id]) > tbody > tr > td:first-child').click(function(e)
{
	if($('body').data('user_id') == $('body').data('logged_user_id')) {
		if(e.target.tagName == "TD") {
			var tr = $(this).parent();
			tr.find('div[data-edit]').toggle();
			tr.find('small').toggle();
			return false;
		}
	}
});

$('table[id="importresults"] > tbody > tr > td a').click(function()
{
	var tr = $(this).closest('tr')
	var title = tr.data('title');
	var status = tr.data('status');
	var episodes = tr.data('episodes');
	$('body').data('info', { status: status, episodes: episodes });
	$('#search-modal').show();
	$.ajax({
		type: "POST",
		url: "/search/anime",
		data: {
			"search" : title,
			"status" : status,
			"episodes" : episodes,
		},
	}).done(function(data){
		$('#modalsearch').val(title);
		$('#modalresults').empty().append(data);
	});
});

$('#modalsearch').keyup(function(event)
{
	if(event.keyCode == 13) {
		var title = $(this).val();
		var body = $('body');
		var status = body.data('info').status;
		var episodes = body.data('info').episodes;
		$.ajax({
			type: "POST",
			url: "/search/anime",
			data: {
				"search" : title,
				"status" : status,
				"episodes" : episodes,
			},
		}).done(function(data){
			$('#modalsearch').val(title);
			$('#modalresults').empty().append(data);
		});
	}
});
