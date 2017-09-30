window.ExtraDrayage =
  init: ->
    ExtraDrayage.multiContainerStyle()

  events: ->
    ExtraDrayage.changeContainerStyle()


  multiContainerStyle: ->
    $('.styles').multiselect
      minWidth: 135
      selectedList: 20
      noneSelectedText: ""
      checkAllText: "All"
      uncheckAllText: "None"

  changeContainerStyle: ->
    $(document).on 'change', '.styles', ->
      $this = $(this)
      $.ajax
        url: '/extra_drayages'
        type: 'POST'
        dataType: 'script'
        data:
          extra_drayage:
            ssline_id: $this.data('ssline-id')
            rail_road_id: $this.data('rail-road-id')
            styles: $this.val()

ExtraDrayage.events()

$(document).on 'turbolinks:load', ->
  ExtraDrayage.init()