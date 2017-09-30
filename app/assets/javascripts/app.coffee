#= require jquery
#= require jquery_ujs
#= require jquery-ui
#= require moment
#= require jquery.facebox
#= require chosen-jquery
#= require jquery_nested_form
#= require cocoon
#= require jquery.multiselect
#= require autocomplete-rails
#= require dataTables/jquery.dataTables
#= require dataTables/extras/dataTables.buttons
#= require fullcalendar
#= require jquery.elevatezoom
#= require dropzone
#= require geocomplete
#= require_directory ./vendors
#= require_directory ./exts
#= require turbolinks

window.App =

  events: ->
    App.autocomplete()
    App.syncData()
    App.placeHolder()
    App.initFacebox()
    App.initDialog()
    App.listenDatePicker()
    App.ajaxCalendarPicker()
    App.initShowHide()
    App.initShowHideAll()
    App.initCheckAll()
    App.clearClearables()
    App.autoArea()
    App.autoSave()
    App.cancelSection()
    App.checkDuplicates()
    App.godaddySeal()
    App.hooks()
    App.zoomImage()

  init: ->
    App.observeForm()
    App.initStickBox()
    App.tabs()
    App.tagsInput()
    App.initPlaceHolder()
    App.chosenSelect()
    App.refreshChosenSelect()
    App.initDateTimePicker()
    App.initAutoHide()
    App.autoRemove()
    App.triggerCheckDuplicates()
    App.copyToClipboard()
    $(window).trigger('resize')

######### Methods ##########
  decodeHtmlEntity: (text)->
    $('<div>').html(text).text()


######### Init #############
  observeForm: ->
    $('.observe-form').each ->
      $(this).observeForm()

  initStickBox: ->
    $(".stickbox").stickySidebar()

  tabs: ->
    $('.tabs').tabs()

  tagsInput: ->
    $('.tagsInput:not(.tagsInited)').each ->
      width = $(this).data('width') || 'auto'
      height = $(this).data('height') || 'auto'
      $(this).addClass('tagsInited').tagsInput
        width: width
        height: height

  initPlaceHolder: ->
    $(".placeholder").each ->
      input = $(this)
      input.blur() unless input.is(':focus')
      input.addClass "black"  unless input.val() is input.attr("title")

    $(".placeholder").parents("form").submit ->
      $(this).find(".placeholder").each ->
        input = $(this)
        input.val ""  if input.val() is input.attr("title")

  initOrResize: ->
    windowHeight = $(window).outerHeight()
    headerHeight = $("#header").outerHeight()
    footerHeight = $("#footer").outerHeight()
    mainHeight = windowHeight - headerHeight - footerHeight
    $("#main").css "min-height", mainHeight
    $('.full-height').css 'height', mainHeight - $('.title-bar').outerHeight() if $('.full-height')

  chosenSelect: ->
    $('.chosen-select').each ->
      width = $(this).data('width') || 250
      $(this).chosen
        allow_single_deselect: true
        no_results_text: ''
        width: width + 'px'

  refreshChosenSelect: ->
    $(".chosen-select").trigger('chosen:updated')

  initDateTimePicker: ->
    $.datepicker.setDefaults dateFormat: "yy-mm-dd"
    $('.date_picker').each ->
      yearRange = $(this).data('year-range') || 'c-10:c+10'
      options =
        changeMonth: true
        changeYear: true
        yearRange: yearRange
      options["maxDate"] = $(this).data('max-date') if $(this).hasData('max-date')
      options["minDate"] = $(this).data('min-date') if $(this).hasData('min-date')
      $(this).datepicker(options)
    $('input.datetime_picker').datetimepicker()

  initAutoHide: ->
    $("#flash-notice").delay(3000).fadeOut("slow")

  triggerCheckDuplicates: ->
    $('.check-dups:not(.inited)').each ->
      $(this).trigger('change') unless $(this).val().blank()

  copyToClipboard: ->
    new Clipboard('.c2c')

######### Events Trigger#########

  autocomplete: ->
    $(document).on 'focus', 'input.autocomplete:not(.inited)', ->
      $this = $(this)
      $this.addClass('inited')
      url = $this.data("url")
      term = $this.data("term")
      form = $this.closest('form')
      symbol = if url.indexOf('?') > 0 then '&' else '?'
      $(this).autocomplete(
        source: (request, response) ->
          $.getJSON url + symbol + form.serialize(),
            term: term
          , response
        select: (e, ui) ->
          window.open(ui.item.url, '_blank') if ui.item.url
        minLength: 3
      ).data("ui-autocomplete")._renderItem = (ul, item) ->
        icon_class = item.icon
        icon_class = '' unless icon_class
        atag = "<a><i class='" + icon_class + "'>&nbsp;</i>" + item.label + "</a>"
        $("<li>").append(atag).appendTo ul

  syncData: ->
    $(document).on 'change', '*[data-sync]', ->
      target = $($(this).data('sync'))
      target.val($(this).val())

  placeHolder: ->
    $(document).on 'focus', '.placeholder', ->
      input = $(this)
      if input.val() is input.attr("title")
        input.val ""

    $(document).on 'blur', '.placeholder', ->
      input = $(this)
      if input.val() is "" or input.val() is input.attr("title")
        input.val input.attr("title")
        input.removeClass "black"

  checkDuplicates: ->
    $(document).on 'change', '.check-dups', ->
      $this = $(this)
      $this.addClass('inited')
      $.ajax
        url: $this.data('url')
        type: 'GET'
        data:
          elem: $this.attr('id')
          term: $this.val() || $(this).data('val')

  ajaxCalendarPicker: ->
    $(document).on "focus", "input.ajax-date-picker:not(.hasDatepicker)", ->
      yearRange = $(this).data('year-range') || 'c-10:c+10'
      $(this).datepicker
        changeMonth: true
        changeYear: true
        onSelect: (dateText, inst) ->
          $.ajax
            url: "/datepickers/" + $(this).data("id")
            type: "PUT"
            data:
              klass: $(this).data("klass")
              method: $(this).data("method")
              "embed-ajax-url": $(this).data("embed-ajax-url")
              date: dateText

    $(document).on "focus", "input.ajax-datetime-picker:not(.hasDatepicker)", ->
      yearRange = $(this).data('year-range') || 'c-10:c+10'
      $(this).datetimepicker
        changeMonth: true
        changeYear: true
        onClose: (dateText, dp_inst, tp_inst) ->
          $.ajax
            url: "/datepickers/" + $(this).data("id")
            type: "PUT"
            data:
              klass: $(this).data("klass")
              method: $(this).data("method")
              "embed-ajax-url": $(this).data("embed-ajax-url")
              date: dateText
              "time-required": true

  listenDatePicker: ->
    $(document).on "click", ".hasDatepicker", ->
      ajax_url = $(this).data("embed-ajax-url")
      if ajax_url
        $.ajax
          url: ajax_url
          type: "GET"

  initDialog: ->
    $(document).on "click", ".dialog", ->
      $("#dialog").dialog("destroy") if $('.ui-dialog').exists()

  showDialog: (options)->
    options||= {}
    options.width||= 750
    options.maxHeight||= 500
    options.modal = true
    options.position =
      my: "center top"
      at: "top"
      of: window
    options.close = (event, ui)->
      $("#dialog").html('')
    $("#dialog").dialog(options)

  initFacebox: ->
    $.facebox.settings.opacity = 0.5;
    $(document).on 'mouseover', 'a[rel*=facebox]', ->
      $(this).facebox $(this).attr('href')
    $(document).on 'mouseout', 'a[rel*=facebox]', ->
      $(this).off('click')

  closeFacebox: ->
    $('#facebox a.close').trigger('click')

  initShowHide: ->
    $(document).on "click", ".show-hide", ->
      rel = $(this).attr("rel")
      if rel isnt `undefined`
        target = $("#" + rel)
      else
        target = $(this).next()
      if target.is(":hidden")
        target.slideDown()
        target.removeClass("hidden")
      else
        target.slideUp()

  initShowHideAll: ->
    $(document).on "click", ".show-hide-all", ->
      klass = $(this).attr("rel")
      if $(this).hasClass('show-all')
        $("." + klass).slideDown().removeClass "hidden"
        $(this).removeClass('show-all')
      else
        $("." + klass).slideUp()
        $(this).addClass('show-all')

  initCheckAll: ->
    $(document).on "click", ".check_all", ->
      if $(this).val() is "none"
        $(this).val "all"
        $("." + $(this).attr("ref")).attr "checked", true
      else
        $(this).val "none"
        $("." + $(this).attr("ref")).attr "checked", false

  godaddySeal: ->
    bgHeight = "433"
    bgWidth = "592"
    $(document).on "click", "#siteseal", (event)->
      event.preventDefault()
      window.open $(this).attr("alt"), "SealVerfication", "location=yes,status=yes,resizable=yes,scrollbars=no,width=" + bgWidth + ",height=" + bgHeight

  clearClearables: ->
    $(document).on "click", ".clear_button", ->
      $(this).closest("form").find(".clearable").each (input) ->
        $(this).val("").trigger("chosen:updated")

  autoRemove: ->
    $(".nospace").observe_field 0.2, ->
      title = $(this).attr("title")
      $(this).val $(this).val().replace(/\s+/g, "")  unless title is $.trim($(this).val())

    $(".nocomma").observe_field 0.2, ->
      $(this).val $(this).val().replace(/\,+/g, "")

  autoArea: ->
    $(document).on 'focus', '.auto-area', ->
      $(this).attr "rows", 3

    $(document).on 'blur', '.auto-area', ->
      $(this).attr "rows", 1

  autoSave: ->
    $(document).on "mouseenter", ".auto-save", ->
      $(this).attr('readonly', false)
    $(document).on "change", ".auto-save", ->
      elem = $(this)
      params = {}
      params["ref"] = elem.attr("ref")
      params["callback"] = elem.attr("callback")
      if elem.is(":checkbox")
        params["val"] = elem.is(':checked') ? "1" : "0"
      else
        params["val"] = elem.val()
      params["respond_id"] = elem.attr("id")
      url = elem.data("url") || "/attrs/0"
      $.ajax
        url: url
        type: "PUT"
        data: $.param(params)

  cancelSection: ->
    $(document).on 'click', '.cancel', ()->
      $(this).closest('.section').slideUp()

  zoomImage: ->
    $(document).on 'mouseover', 'img.zoom-image:not(hasZoom)', ->
      App.removeZoom()
      $(this).elevateZoom(
        constrainType: 'height'
        constrainSize: 400
        zoomType: 'lens'
        lensSize : 400
        containLensZoom: true
        cursor: 'pointer'
        scrollZoom : true
      ).addClass('hasZoom')

  removeZoom: ->
    $('.zoomContainer').remove()

  hooks: ->
    $(document).on 'dialogclose', ->
      App.removeZoom()
    $(document).on 'afterClose.facebox', ->
      App.removeZoom() # to prevent blocking layout by the zoomContainer


###### Once-Call #####
  embedToCalendar: (html) ->
    $(".ui-datepicker-calendar").next().remove()
    $(html).insertAfter ".ui-datepicker-calendar"

  closeDialog: ->
    $("#dialog").dialog(autoOpen: false).dialog("destroy").html("")
    App.removeZoom()

  showNotice: (msg) ->
    $("#flash-notice").html(msg).show().delay(3000).fadeOut("slow")

  countTextMessage: (obj) ->
    $("#char_count").html obj.value.length

  copyTableContent: (target, klass) ->
    copyDiv = $("<div></div>")
    $("#dialog").html copyDiv
    $("#dialog").dialog
      width: 900
      height: 400
      modal: true
      title: "Please use the browser to copy to clipboard (e.g., Ctrl-C)."

    copyDiv.addClass klass
    copyDiv.attr "contentEditable", true
    copyDiv.html $(target).html()
    copyDiv.find(".removeWhenCopy").remove()
    copyDiv.attr "unselectable", "off"
    copyDiv.focus()
    document.execCommand "SelectAll"
    document.execCommand "Copy", true

  markSelection: (checkbox) ->
    tr = checkbox.closest("tr")
    if checkbox.is(":checked")
      tr.addClass "marked"
    else
      tr.removeClass "marked"

  checkAll: (klass, value) ->
    $("." + klass).each ->
      item = $(this)
      item.prop "checked", value
      App.markSelection item
    $("." + klass + ":first").trigger "change"

  checkFirst: (klass) ->
    item = $("." + klass).first()
    item.prop("checked", true).trigger "change"
    App.markSelection item

  checkLast: (klass) ->
    item = $("." + klass).last()
    item.prop("checked", true).trigger "change"
    App.markSelection item

  nextInLine: (klass) ->
    $("." + klass).each ->
      item = $(this)
      unless item.is(":checked")
        item.prop("checked", true).trigger "change"
        App.markSelection item
        false

  newPopup: (url, name, h, w, l, t) ->
    window.open(url, name, "height=" + h + ",width=" + w + ",left=" + l + ",top=" + t + ",resizable=0,scrollbars=1,toolbar=0,menubar=0,location=0,directories=0,status=1")

  removeSiblings: (id) ->
    $(id).siblings().remove()

  loading: ->
    loading = $("#loading")
    loading.css left: ($(window).width() - loading.outerWidth()) / 2
    loading.removeClass('hidden')

  loaded: ->
    $("#loading").addClass('hidden')


$(window).resize ->
  App.initOrResize()

$(document).on
  ajaxStart: ->
    App.loading()

  ajaxStop: ->
    App.init()
    App.loaded()

App.events()

$(document).on 'turbolinks:click', ->
  App.loading()

$(document).on 'turbolinks:load', ->
  App.init()
  App.loaded()

Dropzone.autoDiscover = false
