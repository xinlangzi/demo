# don't use Image as class name. Conflict with facebox
window.Document =

  init: ->
    Document.uploader()

  ##########################
  uploader: ->
    $('.image-uploader').each ->
      selector = '#' + $(this).attr('id')
      new Dropzone(selector,
        url: $(this).data('url')
        dictDefaultMessage: 'Click or drop files to upload'
      ).on('success', (file, response)->
        template = Hogan.compile('<tr data-id="{{uuid}}"><td><a onclick="javascript:App.newPopup(\'\/images\/{{uuid}}\', \'ViewDocument\', 800, 650, 0, 0)" href="javascript: void(0)">{{filename}}</a></td><td width="50"><a data-confirm="Are you sure to delete?" class="red" data-remote="true" rel="nofollow" data-method="delete" href="/images/{{uuid}}">Delete</a></td></tr>')
        html = template.render(response)
        $(this.element).next().append(html)
      )


$(document).on 'turbolinks:load', ->
  Document.init()
