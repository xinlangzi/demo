window.Applicant =

  cdl: null

  init: ->
    new Dropzone("#cdl-uploader",
      url: "/applicants/0/upload"
      dictDefaultMessage: 'Click or drop files to upload'
    ).on('success', (file, response)->
      template = Hogan.compile('<tr id="image_{{id}}"><td><a target="_blank" href="{{url}}">{{filename}}</a></td><td width="80">{{status}}</td><td width="50"><a data-confirm="Are you sure to delete?" class="red" data-remote="true" rel="nofollow" data-method="delete" href="/images/{{uuid}}/delete">Delete</a></td></tr>')
      html = template.render(response)
      $(this.element).next().append(html)
    ) if $('#cdl-uploader').exists()

    $('.dropzone.expir-docs').each ->
      $(this).dropzone
        dictDefaultMessage: 'Click or drop files to upload'
        success: (file, response)->
          template = Hogan.compile('<tr data-id="{{uuid}}"><td><a target="_blank" href="{{url}}">{{filename}}</a></td><td width="80">{{status}}</td><td width="50"><a data-confirm="Are you sure to delete?" class="red" data-remote="true" rel="nofollow" data-method="delete" href="/images/{{uuid}}/delete">Delete</a></td></tr>')
          html = template.render(response)
          $(this.element).next().append(html)

  events: ->
    Applicant.uploadCDL()


##### EVENTS ######

  uploadCDL: ->
    $(document).on 'click', '#upload-cdl', ->
      $(this).attr('disabled', true)
      Applicant.cdl.processQueue()



Applicant.events()

$(document).on 'turbolinks:load', ->
  Applicant.init()
