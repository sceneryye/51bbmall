# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

function show_new_member() {
  $('.new-member-amount').hide();
  $('.new-member-detail').show();
}

function show_new_member_amount(){
  $('.new-member-amount').show();
  $('.new-member-detail').hide();
}
