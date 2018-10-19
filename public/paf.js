var PAF = {
  shrink: function() {
    $(this).parent().children('ul').remove();
    $(this).text('+');
    $(this).css('color', '#00f');
    $(this).one('click', PAF.expand);
  },

  expand: function() {
    var target = $(this).parent();
    var paf = $(this).attr('data-paf');
    $.getJSON('/paf/children', { 'paf': paf }, function(data) {
      var ul = $('<ul></ul>');
      $.each(data, function() {
        var li = $('<li></li>');
        var e = $('<a></a>');
        var a = $('<a></a>');

        e.addClass('expand');
        if (!this.last) {
          e.text('+');
          e.attr('data-paf', this.id);
          e.one('click', PAF.expand);
        } else {
          e.text('·');
          e.css('color', '#fff');
        }

        a.addClass('paf');
        a.text(this.short);
        a.attr('href', this.id);
        $(a).each(PAF.hashLink);

        li.append(e);
        li.append(' ');
        li.append(a);

        ul.append(li);
      });
      target.append(ul);
    });
    $(this).text('-');
    $(this).css('color', '#999');
    $(this).one('click', PAF.shrink);
  },

  show: function() {
    if ( window.location.hash.match(/^#paf/) ) {
      var id = window.location.hash;
      $('#main').fadeOut('fast', function() {
         $.get('/paf/entry', { 'id': id }, function(data) {
          $('#main').html(data);
          $('#main').fadeIn('fast');
          $("#main").removeClass('inactive');
          $('#main a.paf').each(PAF.hashLink);
          $('#main a#show-all').one('click', PAF.all);
          $('html, body').animate({scrollTop:0}, 'fast');
        });
      });
    }
  },

  all: function() {
    if (window.location.hash.match(/^#paf/) ) {
      var id = window.location.hash;
      $('#taxonomy').fadeOut('fast', function() {
        $.get('/paf/lower', { 'id': id }, function(data) {
         $('#main').append(data);
        });
      });
    }
  },

  hashLink: function() {
    var id = $(this).attr('href').match(/\d.+/)
    $(this).attr('href', '#paf-' + id);
  }
}

$(function() {
  $('a.paf').each(PAF.hashLink);
  $(window).bind('hashchange', PAF.show);

  $('a.expand').one('click', PAF.expand);

  $('a#show-advanced').click(function() {
    $(this).remove();
    $('#advanced').fadeIn();
  });

  PAF.show();
});

