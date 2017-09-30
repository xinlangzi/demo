window.Auth =

  init: ->
    if $('#login-form').length > 0
      $('#user_email').val(window.localStorage['email'])
      $('#user_password').val('')

      $(document).on 'click', 'input#login', ->
        window.localStorage['email'] = $('#user_email').val()
        window.localStorage['password'] = ''


$ ->
  Auth.init()