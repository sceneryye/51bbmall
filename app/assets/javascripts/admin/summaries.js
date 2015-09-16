function perPage(x) {
  $.ajax({
    url: '/admin/summaries',
    type: 'GET',
    data: {'per_page':$(x).text()},
    success: function(data) {}
  });
}