window.Report =

  init: ->
    Report.multiSelectPendingTasks()
    Report.tabs()

  multiSelectPendingTasks: ->
    $('#multi-select-pending-tasks').multiselect
      selectedList: 6
      minWidth: 600
      checkAllText: "All"
      uncheckAllText: "None"
      noneSelectedText: "Please Select"

  tabs: ->
    $("#tabs").tabs();

$(document).on 'turbolinks:load', ->
  Report.init()
