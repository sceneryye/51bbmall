$('.page-numbers').on('click', function perPage() {
  $.ajax({
    url: '/admin/summaries',
    type: 'GET',
    data: {'per_page':$(this).text()},
    success: function(data) {}
  });
})