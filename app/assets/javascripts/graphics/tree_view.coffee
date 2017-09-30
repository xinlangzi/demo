window.TreeView =

  init: ->
    TreeView.reportByCategory()

  reportByCategory: ->
    if $('#report-by-category').length > 0
      $(".total").each ->
        total = new BigDecimal("0.00")
        $(this).closest("li").find(".unit").each ->
          total = total.add(new BigDecimal($(this).attr("rel")))
        $(this).closest("li").attr "rel", parseFloat(total).toFixed(2)
        $(this).html "$" + parseFloat(total).toFixed(2).commafy()

      $(".classify").each ->
        total = new BigDecimal("0.00")
        $(this).find(".unit").each ->
          total = total.add(new BigDecimal($(this).attr("rel")))  unless $(this).hasClass("no_summary")
        $(this).find(".summary").html "$" + parseFloat(total).toFixed(2).commafy()

      setTimeout( ->
        $(".tree").jstree
          core:
            themes:
              theme: "default"
              icons: false
              stripes: true
      , 1500)

$(document).on 'turbolinks:load', ->
  TreeView.init()