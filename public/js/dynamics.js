var main = function () {
	$('#prod-buy').mouseenter(function(e){
		$(e.target).css("background-color","white");
		$(e.target).css("color","#322E34");
		$(e.target).css("border","1px solid #322E34");

	});
	$('#prod-buy').mouseleave(function(){
		$(this).css("background-color","#322E34");
		$(this).css("color","white");
		$(this).css("border","none");

	});
};
$(document).ready(main);