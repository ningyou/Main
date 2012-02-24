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
