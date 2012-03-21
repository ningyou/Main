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
	var searchType = $("#searchtype").val()
	$.ajax({
		type: "POST",
		url: "/search/"+searchType,
		data: $("#search").serializeArray(),
	}).done(function(data){
		$("#searchbox").val('');
		$("#result").empty().append(data);
	});
})

$('table > tbody > tr > td:last-child > a:nth-child(2)').click(function()
{
	var id = $(this).parents('tr').data('id');
	var ep = $(this).parent().find('a:first').html().split('/')[0] | 0;
	var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
	var status = $(this).parents('table').find('th').html().split("(")[0].trim();
	var refresh = $(this).parents('table').find('thead > tr > th > div > a:first-child')
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
				topalert('Status set to Completed.');
				refresh.show()
			}
		});
	}, 500)
	return false;
});

$('table > tbody > tr > td:last-child > a:first-child').click(function()
{
	var status = $(this).parents('table').find('th').html().split("(")[0].trim();
	var ep = $(this).html().split('/')[0];
	$(this).hide();
	$(this).parent().find('a:last').hide()
	$(this).parent().find('input').show('fast').val(ep).select();
	return false;
});

$('table > tbody > tr > td:last-child > input').keyup(function(event)
{
	var id = $(this).parents('tr').data('id');
	if(event.keyCode == 13) {
		var ep = $(this).val() | 0;
		var total = $(this).parent().find('a:first').html().split('/')[1] | 0;
		var status = $(this).parents('table').find('th').html().split("(")[0].trim();
		var refresh = $(this).parents('table').find('thead > tr > th > div > a:first-child')
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
				topalert('Status set to Completed.');
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
	$(this).hide();
	$(this).parent().find('a').show()
});

$('table > thead > tr > th > div > a:last-child').click(function()
{
	$(this).parents('table').find('div[data-edit]').toggle();
	$(this).parents('table').find('small').toggle();
	return false;
});

$('table > thead > tr > th > div > a:first-child').click(function()
{
	location.reload();
});

$('table > tbody > tr > td > div > select').change(function()
{
	$(this).parents('table').find('thead > tr > th > div > a:first-child').show();
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
	var id = $(this).parents('tr').data('id');
	$.ajax({
		type: "POST",
		url: "/del/show",
		data: { 
			"id" : id,
			"list_name" : list_name,
			"user" : logged,
		}
	});
	$(this).parents('tr').remove();
	return false;
});

