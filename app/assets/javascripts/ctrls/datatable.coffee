window.DataTable =

  init: ->
    setTimeout( ->
      DataTable.build()
    , 1000)

  build: ->
    $(".datatable-config").each ->
      table = $(this).prev()
      unless table.hasClass('dataTables_wrapper')
        options = $.parseJSON($(this).text())
        DataTable.wrapper table, options

  destroy: (selector)->
    $(selector).each ->
      $(this).closest("table").dataTable().fnDestroy()

  draw: (selector, clear)->
    clear = (if typeof clear is "undefined" then false else clear)
    $(selector).each ->
      table = $(this).closest("table")
      options = $.parseJSON(table.next().text())
      DataTable.wrapper(table, options, clear)

  wrapper: (table, options, clear)->
    # options["fnStateSaveCallback"] = (settings, oData) ->
    #   localStorage.setItem "DataTables_" + settings.sInstance + location.pathname, JSON.stringify(oData)
    #
    # options["fnStateLoadCallback"] = (oSettings) ->
    #   oData = JSON.parse(localStorage.getItem("DataTables_" + settings.sInstance + location.pathname))
    #   oData["oSearch"]["sSearch"] = ""  if clear and oData
    #   oData
    dt = table.DataTable(options)
    hColumns = options["hiddenColumns"] || []
    $.each hColumns, (index, name)->
      dt.column(':equals(' + name + ')' ).visible(false)
    table.css("width", "100%")

  clearStates: ->
    $('table.dataTable').each ->
      $(this).DataTable().table().state.clear()

$(document).on 'turbolinks:load', ->
  DataTable.init()

$(document).on 'ajaxStop', ->
  DataTable.build()
