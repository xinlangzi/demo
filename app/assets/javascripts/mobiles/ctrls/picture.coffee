window.Picture =

  captured: []

  navbarTemplate: '<div class="navbar">
    <div class="navbar-inner">
        <div class="left sliding">
            <a href="#" class="link close-popup photo-browser-close-link">
                <i class="icon icon-back"></i>
                <span>Close</span>
            </a>
        </div>
        <div class="center sliding">
            <span class="photo-browser-current"></span> <span class="photo-browser-of">of</span> <span class="photo-browser-total"></span>
        </div>
        <div class="right">
          <a class="save icon icon32 ion-ios-download-outline"></a>
        </div>
    </div>
</div>'

  toolbarTemplate: '<div class="toolbar tabbar doc-slide-toolbar">
    <div class="toolbar-inner">
        <a href="#" class="link photo-browser-prev"><i class="icon ion-ios-arrow-back"></i></a>
        <a href="#" class="link delete"><i class="icon ion-ios-trash-outline"></i></a>
        <a href="#" class="link photo-browser-next"><i class="icon ion-ios-arrow-forward"></i></a>
    </div>
</div>'


  init: ->
    Picture.capture()
    Picture.submit()
    Picture.viewAll()
    Picture.save()
    Picture.deleteFromSlide()
    Picture.deleteFromCard()

  viewAll: ->
    $(document).on 'change', '.search-docs input', ->
      data = {}
      data[$(this).attr('name')] = $(this).val()
      $.getJSON('/docs/search',
        data,
        format: 'json').done (data) ->
          if data.length > 0
            F7H.app.photoBrowser(
              photos: data
              type: 'popup'
              navbarTemplate: Picture.navbarTemplate
              toolbarTemplate: Picture.toolbarTemplate
            ).open()
            $(data).each (index, item)->
              $('img[src="' + item.url + '"]').attr('id', item.id)
          else
            F7H.app.alert("No images.", "")

  save: ->
    $(document).on 'click', 'a.save', ->
      F7H.app.alert("Press on image to save.", "Save Picture")

  deleteFromSlide: ->
    $(document).on 'click', '.doc-slide-toolbar a.delete', ->
      img = $('.swiper-slide-active img')
      id = img.attr('id')
      $.ajax
        url:'/docs/' + id
        type: 'DELETE'
        dataType: 'json'
        beforeSend: (xhr)->
          Loading()
        success: (response)->
          ClearNotifications()
          F7H.app.addNotification
            title: 'Congratulations'
            message: response.message
          img.css('opacity', 0.75)
          Loaded()
        error: (xhr, status, error)->
          F7H.app.alert(xhr.responseText, "Warning")
          Loaded()

  deleteFromCard: ->
    $(document).on 'click', '.doc-card a.delete', ->
      id = $(this).data('id')
      card = $(this).closest('.card')
      F7H.app.confirm 'Are you sure to delete?', '', (->
        $.ajax
          url:'/docs/' + id
          type: 'DELETE'
          dataType: 'json'
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            ClearNotifications()
            F7H.app.addNotification
              title: 'Congratulations'
              message: response.message
            Loaded()
            card.slideUp()
            J1s.reload()
          error: (xhr, status, error)->
            F7H.app.alert(xhr.responseText, "Warning")
            Loaded()
        return
      ), ->
        return

  submit: ->
    $(document).on 'submit', 'form#image-form', (e)->
      e.preventDefault()
      fd = new FormData()
      form = $(this)
      if Picture.captured.length == 0
        F7H.app.alert("Pleaes capture at least one picture!", "Warning")
      else
        $(Picture.captured).each (index, file)->
          fd.append("files[" + index + "]", file)
        fd.append(x.name, x.value) for x in form.serializeArray()
        $.ajax
          url: form.attr('action')
          method: 'POST'
          contentType: false
          dataType: 'json'
          data: fd
          processData: false
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            eval(response.js) if response.js
            ClearNotifications()
            F7H.app.addNotification
              title: 'Thank you'
              message: response.message
            Picture.clearCaptured()
            Loaded()
          error: (xhr, status, error)->
            ul = $('<ul>').addClass('error-recap')
            $.each xhr.responseJSON, (index, error) ->
              error = index + 1 + ". " + error
              ul.append($('<li>').html(error))
            $('.error-messages').html(ul)
            Loaded()

  capture: ->
    $(document).on 'change', '#image-form .camera-input', (e)->
      file = e.target.files[0]
      reader = new FileReader()
      max = $(e.target).data('max') || 10
      if file
        Picture.captured.push(file)
        reader.readAsDataURL(file)
      reader.onload = ->
        div = $('<div class="col-33 image">')
        div.append($('<div class="icon ion-ios-close remove">'))
        div.append($('<img>').attr('src', reader.result))
        $('.add-image').after(div)
        $('.add-image').hide() if Picture.captured.length >= max
        $(div).find('.remove').click ->
          div.remove()
          Picture.captured.splice(Picture.captured.indexOf(file), 1)
          $('.add-image').show() if Picture.captured.length < max

  clearCaptured: ->
    Picture.captured = []
    $('.image').remove()

$ ->
  Picture.init()
