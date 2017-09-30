#= require framework7
#= require moment
#= require fullcalendar
#= require jquery_nested_form
#= require ./framework7/framework7.3dpanels
#= require ./mobiscroll/mobiscroll
#= require ./../ctrls/google_map
#= require ./../vendors/jquery.observe_field
#= require ./../ctrls/track_trucks
#= require ./jquery.oLoader
#= require ./signature_pad
#= require_tree ./ctrls


window.F7H =
  app: new Framework7(
    cacheDuration: 1000 * 30
    # swipePanel: 'left'
  )
  dom: Framework7.$

window.Phone =
  Views: {}

Phone.Views.Main =
  F7H.app.addView '.view-main',
    dynamicNavbar: true
    smartSelectBackOnSelect: true

$$ = Dom7

window.Loading = ->
  $('.views').oLoader
    backgroundColor:'rgba(0, 0, 0, 0.8)'
    image: '/assets/img/loader1.gif'
    fadeInTime: 500
    fadeOutTime: 1000
    fadeLevel: 0.7

window.Loaded = ->
  $('.views').oLoader('hide')

window.OpenAjaxPopup = (url)->
  $.ajax
    url: url
    type: 'GET'
    dataType: 'html'
    success: (html)->
      html = '<div class="popup popup-ajax"><div class="content-block top-block"><div class="header"><a href="#" class="close-popup">✕ Close</a></div>'+ html + '</div></div>'
      F7H.app.popup(html)

window.CloseAjaxPopup = ->
  F7H.app.closeModal('.popup-ajax')

window.ClearNotifications = ->
  F7H.app.closeNotification(".notifications")

$(document).on 'submit', 'form.load-page', (e)->
  e.preventDefault()
  form = $(this)
  url = form.attr('action')
  data =  form.serialize()
  Phone.Views.Main.loadPage(url + '?' + data)

$(document).on 'click', 'a.ajax-popup', ->
  OpenAjaxPopup($(this).data('url'))

$(document).on 'focus', 'input.date_picker', ->
  $(this).mobiscroll().date
    theme: 'ios'
    dateFormat: 'yy-mm-dd'

$(document).on 'click', '.clear-date', ->
  target = $(this).data('target')
  $('.'+target).val('')

$(document).on 'click', '.hidden-link', ->
  url = $(this).data('url')
  Phone.Views.Main.loadPage(url)

$(document).on "change", ".auto-save", ->
  elem = $(this)
  params = {}
  params["ref"] = elem.attr("ref")
  if elem.is(":checkbox")
    params["val"] = elem.is(':checked') ? "1" : "0"
  else
    params["val"] = elem.val().trim()
  $.ajax
    url: '/attrs/0'
    type: 'PUT'
    dataType: 'json'
    data: $.param(params)
    success: (response)->
      ClearNotifications()
      F7H.app.addNotification
        title: 'Great!'
        message: response.message
      elem.next().removeClass().addClass(response.alter_status)
    error: (xhr, status, error)->
      F7H.app.alert(xhr.responseJSON.error, "Warning")

$(".nospace").observe_field 0.2, ->
  title = $(this).attr("title")
  $(this).val $(this).val().replace(/\s+/g, "") unless title is $.trim($(this).val())

$(document).on
  ajaxStart: ->
    Loading()
  ajaxComplete: ->
    Loaded()

## Execute codes when page inited
$$(document).on 'pageInit', (e)->
  SwiperSlide.init()
  DayLog.init()
