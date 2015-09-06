$(document).ready(function(){
	var pWin = window.parent;
	var pDoc = window.parent.document;
	
	$(".products-quantity").on("change",function(){
	
		var quantity = parseInt($(this).val());
		console.log(quantity);
		console.log($(this).attr('data-url'));
		if(!/\d+/.test(quantity)) return false;
		var url = $(this).attr('data-url');

		$.ajax({
			url: url,
			type: "PUT",
			data:{ quantity:quantity },
			success:function(res){
				alert('ok');
				alert(res);
			}
		});
	});

});