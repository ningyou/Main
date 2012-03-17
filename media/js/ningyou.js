$(function () {
	var $alert = $('#top-alert');
	if($alert.length)
	{
		var alerttimer = window.setTimeout(function () {
			$alert.trigger('click');
		}, 3000);
		$alert.animate({height: $alert.css('line-height') || '50px'}, 200)
		.click(function () {
			window.clearTimeout(alerttimer);
			$alert.animate({height: '0'}, 200);
		});
	}
});

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

if(user = logged) {
	$('a[id^="incr"]').on('click', function()
	{
		var row_id = $(this).attr('id').split('_')[1];
		var ep = $('#add_link_'+row_id).html().split('/')[0];
		var total = $('#add_link_'+row_id).html().split('/')[1] | 0;
		var complete = false;
		ep++;
		if(total) {
			if(ep >= total) { ep = total; complete = true; }
		} else {
			total = "??";
		}
		$('#add_link_'+row_id).empty().append(ep+"/"+total);
		if(this.request) { clearTimeout(this.request) }
		this.request = setTimeout(function() { 
			$.ajax({
			type: "POST",
			url: "/add/episode",
			data: { 
				"id" : row_id, 
				"episodes" : ep,
				"list_name" : list_name,
				"user" : logged,
				"complete" : complete,
			}
			});
		}, 500)
		return false;
	});
	$('a[id^="add_link"]').on('click', function()
	{
		var row_id = $(this).attr('id').split('_')[2];
		var ep = $(this).html().split('/')[0];
		$(this).hide();
		$('#incr_'+row_id).hide();
		$('#add_input_'+row_id).show("fast").val(ep).select();
		return false;
	});
	$('input[id^="add_input"]').keyup(function(event)
	{
		var row_id = $(this).attr('id').split('_')[2];
		if(event.keyCode == 13) {
			var ep = $(this).val() | 0;
			var total = $('#add_link_'+row_id).html().split('/')[1] | 0;
			var complete = false;
			if(total) {
				if(ep >= total) { ep = total; complete = true; }
			} else {
				total = "??";
			}
			if(ep < 0) { ep = 0;}
			$(this).hide().focusout();
			$('#add_link_'+row_id).empty().append(ep+"/"+total);
			$.ajax({
				type: "POST",
				url: "/add/episode",
				data: { 
					"id" : row_id, 
					"episodes" : ep,
					"list_name" : list_name,
					"user" : logged,
					"complete" : complete,
				}
			});
		}
		if(event.keyCode == 27) {
			$(this).hide().focusout();
		}
	});
	$('input[id^="add_input"]').focusout(function()
	{
		var row_id = $(this).attr('id').split('_')[2];
		$(this).hide();
		$('#add_link_'+row_id).show();
		$('#incr_'+row_id).show();
	});
	$('table > thead > tr > th > a').on("click", function()
	{
		var time = new Date().getTime();
		$(this).parents('table').find('select').toggle();
		$(this).parents('table').find('small').toggle();
		var diff = new Date().getTime()-time;
		console.log(diff);
		return false;
	});
}
