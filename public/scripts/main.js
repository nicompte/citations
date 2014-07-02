$(function(){

  /*
  * BOOTSTRAP & jQuery
  */

  $('#private-quote-label, #edit-private-quote-label').tooltip();
  $('.edit-quote, .delete-quote, .star-quote, .unstar-quote').tooltip();

  jQuery.extend(jQuery.validator.messages, {
    required: "Veuillez renseigner ce champ.",
    email: "Veuillez saisir une adresse email valide."
  });

  jQuery.validator.setDefaults({
    highlight: function(element) {
      $(element).closest('.form-group').addClass('has-error');
    },
    unhighlight: function(element) {
      $(element).closest('.form-group').removeClass('has-error');
    },
    errorElement: 'span',
    errorClass: 'help-block',
    errorPlacement: function(error, element) {
      if(element.parent('.input-group').length) {
        error.insertAfter(element.parent());
      } else {
        error.insertAfter(element);
      }
    }
  });

  $("#register").validate();
  $("#login").validate();
  $("#add").validate();

  /*
  * PAGINATION
  */

  $('.pagination .first a').html("«");
  $('.pagination .prev a').html("‹");
  $('.pagination .next a').html("›");
  $('.pagination .last a').html("»");

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
      window.location.href = "/";
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
  * STAR
  */
  $('.star-quote').on('click', function(){
    var self = $(this);
    $.ajax({
      url: $(this).attr('href'),
      method: 'PUT'
    }).done(function(){
      self.removeClass('star-quote').addClass('unstar-quote')
      .attr('href', self.attr('href').replace('star', 'unstar'))
      .attr('title', 'Retirer des favoris');
    });
    event.preventDefault();
    return false;
  });

  $('.unstar-quote').on('click', function(){
    var self = $(this);
    $.ajax({
      url: $(this).attr('href'),
      method: 'PUT'
    }).done(function(){
      self.removeClass('unstar-quote').addClass('star-quote')
      .attr('href', self.attr('href').replace('unstar', 'star'))
      .attr('title', 'Ajouter aux favoris');
    });
    event.preventDefault();
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
    if($(this).valid()){
      $.ajax({
        url: '/login',
        method: 'post',
        data: $(this).serialize()
      }).done(function(){
        window.location.reload();
      }).fail(function(){
        alert('Erreur lors de la connexion.');
      });
    }
    return false;
  });

  /*
  * REGISTER
  */

  $('#register-link').on('click', function(){
    $('#registerModal').modal('show');
    return false;
  });

  $('#register').on('submit', function(){

  });

  /*
  * EDIT AUTHOR
  */

  $('.edit-author').on('click', function(){
    $('#author-to-edit').val($(this).attr('data-id'));
    $('#author-to-edit-author').val($(this).attr('data-value'));
    $('#editAuthorModal').modal('show');
    return false;
  });

  /*
  * EDIT BOOK
  */

  $('.edit-book').on('click', function(){
    $('#book-to-edit').val($(this).attr('data-id'));
    $('#book-to-edit-book').val($(this).attr('data-value'));
    $('#editBookModal').modal('show');
    return false;
  });

});
