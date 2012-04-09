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
		top_alert.animate({height: '0'}, 200);
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

$('table > tbody > tr > td:last-child > a:nth-child(2)').click(function()
{
	var table = $(this).closest('table');
	var tr = $(this).closest('tr');
	var id = tr.data('id');
	var title = tr.data('title');
	var ep = $(this).parent().find('a:first').html().split('/')[0] | 0;
	var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
	var status = table.find('th').data('status');
	var refresh = table.find('thead > tr > th > div > a:first-child')
	ep++;
	if(total) {
		if(ep >= total) { ep = total; status = "Completed"; }
	} else {
		total = "?";
	}
	$(this).parent().find('a:first').empty().append(ep+'/'+total);
	if(this.request) { clearTimeout(this.request) }
	this.request = setTimeout(function() { 
	$.ajax({
		type: "POST",
		url: "/add/episode",
			data: {
				"id" : id,
				"episodes" : ep,
				"list_name" : list_name,
				"user" : logged,
				"status" : status,
			}
		}).done(function()
		{
			if(status == "Completed")
			{
				topalert(title+': Status set to Completed.');
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
	if(event.keyCode == 13) {
		var ep = $(this).val() | 0;
		var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
		var status = table.find('th').data('status');
		var refresh = table.find('thead > tr > th > div > a:first-child')
		if(total) {
			if(ep >= total) { ep = total; status = "Completed"; }
		} else {
			total = "?";
		}
		if(ep < 0) { ep = 0;}
		$(this).hide().focusout();
		$(this).parent().find('a:first').empty().append(ep+'/'+total);
		$.ajax({
			type: "POST",
			url: "/add/episode",
			data: {
				"id" : id,
				"episodes" : ep,
				"list_name" : list_name,
				"user" : logged,
				"status" : status,
			}
		}).done(function()
		{;
			if(status == "Completed")
			{
				topalert(title+': Status set to Completed.');
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
	var id = $(this).parents('tr').data('id');
	var status = $(this).val();
	$.ajax({
		type: "POST",
		url: "/add/episode",
		data: {
			"id" : id,
			"list_name" : list_name,
			"user" : logged,
			"status" : status,
		}
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
			"list_name" : list_name,
			"user" : logged,
		}
	});
	tr.remove();
	return false;
});

$('table > tbody > tr > td > a:first-child').click(function(e)
{
	if(e.shiftKey) {
		var tr = $(this).parent();
		tr.find('div[data-edit]').toggle();
		tr.find('small').toggle();
		return false;
	}
});

$('table[id="importresults"] > tbody > tr > td a').click(function()
{
	var title = $(this).closest('tr').data('title');
	$('#search-modal').show();
	$.ajax({
		type: "POST",
		url: "/search/anime",
		data: {
			"search" : title,
		},
	}).done(function(data){
		$('#modalsearch').val(title);
		$('#modalresults').empty().append(data);
	});
});

$('#modalsearch').keyup(function(event)
{
	if(event.keyCode == 13) {
		var title = $(this).val()
		$.ajax({
			type: "POST",
			url: "/search/anime",
			data: {
				"search" : title,
			},
		}).done(function(data){
			$('#modalsearch').val(title);
			$('#modalresults').empty().append(data);
		});
	}
});
