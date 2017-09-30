$.fn.extend
  exists: ->
    return $(this).length > 0

  blank: ->
    return $(this).val().trim().length == 0

  hasData: (attr)->
    return $(this).data(attr) != undefined

  valList: ->
    $.map this, (elem) ->
      elem.value || ""
$.expr[':']['equals'] = (node, index, props)->
  node.innerText == props[3]

String::commafy = ->
  @replace /(^|[^\w.])(\d{4,})/g, ($0, $1, $2) ->
    $1 + $2.replace(/\d(?=(?:\d\d\d)+(?!\d))/g, "$&,")
String::blank = ->
  $.trim(this) is ""

Number::round = (n) ->
  n = 0  unless parseInt(n)
  return false  if not parseFloat(this) and parseFloat(this) isnt 0
  Math.round(this * Math.pow(10, n)) / Math.pow(10, n)

Number::commafy = ->
  String(this).commafy()

$.isBlank = (obj) ->
  not obj or $.trim(obj) is ""


sleep = (milliseconds) ->
  start = (new Date).getTime()
  i = 0
  while i < 1e7
    if (new Date).getTime() - start > milliseconds
      break
    i++
  return
