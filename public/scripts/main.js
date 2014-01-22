$(function(){

  /*
  * DELETE
  */

  $('.delete-quote').on('click', function(){
    $('#quote-to-delete').val($(this).attr('data-id'));
    $('#deleteQuoteModal').modal('show');
    return false;
  });

  $('#delete').on('submit', function(){
    $.ajax({
      url: '/quote/' + $('#quote-to-delete').val(),
      method: 'delete'
    }).done(function(){
      window.location.reload();
    }).fail(function(){
      alert('Erreur lors de la suppression.');
    });
    return false;
  });

  /*
  * ADD
  */

  $('#add-quote').on('click', function(){
    $('#addQuoteModal').modal('show');
    return false;
  });

  // $('#add').on('submit', function(){
  //   $.ajax({
  //     url: '/quote/' + $('#quote-to-edit').val(),
  //     method: 'put',
  //     data: $(this).serialize()
  //   }).done(function(){
  //     window.location.reload();
  //   }).fail(function(){
  //     alert('Erreur lors de la modification.');
  //   });
  //   return false;
  // });

  $('#author').selectize({
      valueField: '_id', labelField: 'name',
      searchField: 'name', create: true, maxItems: 1,
      render: {
        option_create: function(data, escape) {
          return '<div class="create">Ajouter <strong>' + escape(data.input) + '</strong>&hellip;</div>';
        }
      },
      load: function(query, callback) {
        if (!query.length) return callback();
        $.ajax({
          url: '/author/find/' + encodeURIComponent(query), type: 'GET',
          error: function() { callback(); },
          success: function(res) { callback(res.slice(0, 10)); }
        });
      }
    });

    $('#book').selectize({
      valueField: '_id', labelField: 'name',
      searchField: 'name', create: true, maxItems: 1,
      render: {
        option_create: function(data, escape) {
          return '<div class="create">Ajouter <strong>' + escape(data.input) + '</strong>&hellip;</div>';
        }
      },
      load: function(query, callback) {
        if (!query.length) return callback();
        $.ajax({
          url: '/book/find/author/' + $('#author').val() + '/book/' + encodeURIComponent(query), type: 'GET',
          error: function() { callback(); },
          success: function(res) { callback(res.slice(0, 10)); }
        });
      }
    });


  /*
  * EDIT
  */

  $('.edit-quote').on('click', function(){
    $('#quote-to-edit').val($(this).attr('data-id'));
    $('#quote-to-edit-author').val($(this).siblings('.author').find('a').html());
    $('#quote-to-edit-book').val($(this).siblings('.book').find('a').html());
    $('#quote-to-edit-quote').val($(this).parents('.quote').find('.text').html());
    $('#quote-to-edit-hidden').prop('checked', $(this).siblings('.hidden').val() == "true");
    $('#editQuoteModal').modal('show');
    return false;
  });

  $('#edit').on('submit', function(){
    $.ajax({
      url: '/quote/' + $('#quote-to-edit').val(),
      method: 'put',
      data: $(this).serialize()
    }).done(function(){
      window.location.reload();
    }).fail(function(){
      alert('Erreur lors de la modification.');
    });
    return false;
  });

  /*
  * LOGIN
  */

  $('#login-link').on('click', function(){
    $('#loginModal').modal('show');
    return false;
  });

  $('#login').on('submit', function(){
    $.ajax({
      url: '/login',
      method: 'post',
      data: $(this).serialize()
    }).done(function(){
      window.location.reload();
    }).fail(function(){
      alert('Erreur lors de la connexion.');
    });
    return false;
  });

});