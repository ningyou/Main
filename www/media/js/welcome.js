var ningyou = {
	fillCheck: function() {
		if ( ($(".button.active").attr("id") == "btn_signup"
			&& ($("#f_user").val().length > 0
			&& $("#f_pass").val().length > 0
			&& $("#f_email").val().length > 0))
			|| ($(".button.active").attr("id") == "btn_login"
			&& ($("#f_user").val().length > 0
			&& $("#f_pass").val().length > 0)) )
			$("#f_submit").removeAttr("disabled").removeClass("disabled");
		else
			$("#f_submit").attr("disabled", "true").addClass("disabled");
	},
	signup: function() {
		if (this.parentNode.className != "active") {
			$("#btn_signup").addClass("active");
			$("#btn_login").removeClass("active");
			$("#for_signup").css("display", "block").animate({
				height: "48px",
				opacity: 1.0
			}, "fast");
			$(".for_signup").fadeIn(250);
			$(".for_login").fadeOut(250);
			$("#f_user").focus();
			ningyou.fillCheck();
		}
	},
	login: function() {
		if (this.parentNode.className != "active") {
			$("#btn_signup").removeClass("active");
			$("#btn_login").addClass("active");
			$("#for_signup").animate({
				height: "0px",
				opacity: 0.0
			}, "fast", function() {
				$(this).css("display", "none");
			});
			$(".for_login").fadeIn(250);
			$(".for_signup").fadeOut(250);
			$("#f_user").focus();
			ningyou.fillCheck();
		}
	}
};

$(document).ready(function() {
	$(".for_signup").css("display", "block");
	$("#f_submit").attr("disabled", "true").addClass("disabled");
	$("input").focusout(function() {
		if ($(this).val().length > 0)
			$(this).attr("class", "hasContent");
		else
			$(this).attr("class", "");
	}).keyup(ningyou.fillCheck).change(ningyou.fillCheck);
	
	window.setTimeout(function() {
		ningyou.fillCheck();
		$("input").each(function() {
			if ($(this).val().length > 0)
				$(this).attr("class", "hasContent");
		});
	}, 250);
});