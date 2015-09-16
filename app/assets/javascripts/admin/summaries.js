function perPage(x) {
  var num = parseInt($(x).text());
  var addr = window.location.href.split('?');
  if(addr.length == 1 || addr[1].slice(0,3) == 'per') {
    $(x).attr('href', window.location.pathname + '?per_page=' + num);
  }
  else if(addr[1].slice(0, 5) == 'index') {
    var newAttr = window.location.pathname + '?' + addr[1].split('&')[0] + '&per_page=' + num;
    $(x).attr('href', newAttr);
  }

}

