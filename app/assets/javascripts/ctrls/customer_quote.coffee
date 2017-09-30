window.CustomerQuote =

  init: ->
    CustomerQuote.validateForm()
    CustomerQuote.portEntryExit()
    CustomerQuote.typeOnSize()
    CustomerQuote.cargoWeight()
    CustomerQuote.popUpHazardous()
    CustomerQuote.listenForRailRoads()
    CustomerQuote.listenForZipCode()
    CustomerQuote.multiSslines()
    CustomerQuote.calculateButton()
    CustomerQuote.initSelections()

  validateForm: ->
    $('#customer-quote').validate
      ignore: []
      onfocusout: (element)->
        $(element).valid();
      errorPlacement: (error, element) ->
        if element.hasClass("multiselect")
          error.insertAfter element.next()
        else
          error.insertAfter element
        return

  portEntryExit: ->
    $(document).on 'change', '#port', ->
      CustomerQuote.clearRailMiles()
      $this = $(this)
      $.ajax
        url: '/ports'
        type: 'GET'
        dataType: 'script'
        data:
          id: $this.val()
  typeOnSize: ->
    enables =
      20: ["DV", "FR", "OT", "RF", "TANK"]
      40: ["DV", "DV OT", "DV RF", "FR", "HC", "HC RF", "OT", "TANK"]
      45: ["DV", "HC"]
      53: ["DV"]

    $(document).on "change", ".container-size", ->
      $this = $(this)
      size = $this.find('option:selected').text()
      $type = $this.closest('.size-type').find('.container-type')
      $type.find('option').removeClass('hidden')
      if size != ''
        $type.find('option').addClass('hidden')
        $(enables[size]).each (index, name)->
          $type.find('option').filter ->
            $(this).removeClass('hidden') if $(this).text()==name
        $type.val('') if $type.find('option:selected').hasClass('hidden')
    $('.container-size').trigger('change')

  cargoWeight: ->
    $(document).on 'change', '.trigger-cargo-weight', ->
      $csize = $('#csize').val()
      $ctype = $('#ctype').val()
      $.ajax
        url: '/quote_engines/cargo_weight'
        type: 'GET'
        dataType: 'script'
        data:
          csize: $csize
          ctype: $ctype

  popUpHazardous: ->
    $(document).on 'change', '#hazardous', ->
      $this = $(this)
      if $this.val() == "1"
        alert('We do not haul hazardous cargo')
        $this.val(0)

  listenForZipCode: ->
    $(document).on 'click', "#dest", ->
      $(this).focus()

    $(document).on 'blur', '#dest', ->
      setTimeout( ->
        CustomerQuote.requestDirections()
      , 500)

    $(document).on 'focus', '#dest', ->
      $(this).geocomplete
        country: 'us'

  listenForRailRoads: ->
    $(document).on 'change', '#src', ->
      CustomerQuote.requestDirections()

  requestDirections: ->
    $dest = $('#dest')
    $src = $('#src')
    $calculate = $('#calculate')
    if not $dest.val().blank()
      $calculate.attr('disabled', true)
      $calculate.val('Getting Routes')
      CustomerQuote.clearRailMiles()
      $.ajax
        url: '/google_map/routes'
        type: 'GET'
        dataType: 'script'
        data:
          rrid: $src.val()
          dest: $.trim($dest.val())

  clearRailMiles: ->
    $("#rail_miles").val('');
    $("#dest_detail").html('')
    $("#dest_address").val('')

  multiRailRoads: ->
    $('#rrid select').multiselect
      selectedList: 4
      minWidth: 250
      checkAllText: "All"
      uncheckAllText: "None"
      noneSelectedText: "Please Select"
    $('#rrid button').css('width', '245px')
    $('.ui-multiselect-menu').width(245)

  multiSslines: ->
    $('#ssid select').multiselect
      selectedList: 4
      minWidth: 150
      checkAllText: "All"
      uncheckAllText: "None"
      noneSelectedText: "Not Sure"
      beforeopen: ()->
        $(this).multiselect('widget').find('.ui-helper-reset li:first').hide()
    $('#ssid button').css('width', '200px')
    $('.ui-multiselect-menu').width(250)

  multiCargoWeight: ->
    $('#cargo_weight select').multiselect
      selectedList: 4
      minWidth: 225
      checkAllText: "All"
      uncheckAllText: "None"
      close: ->
        $("#cargo_weight select").valid()
    $('#cargo_weight button').css('width', '200px')
    $('.ui-multiselect-menu').width(250)

  calculateButton: ->
    $(document).on 'click', '#calculate', ->
      if $("#dest_detail").html() is "Invalid Zip"
        alert "Please provide a valid zip code!"
        return false
      if $("#rail_miles").val().blank()
        alert "Please provide a valid rail road!"
        return false
      true

  verifyRailMiles: ->
    routes = parseInt($("#rail_routes").val())
    maps = $.grep($("#rail_miles").val().split("|"), (n, i) ->
      not n.blank()
    )
    if maps.length is routes
      $("#calculate").removeAttr "disabled"
      $("#calculate").val "Calculate Quote"

  loadedDirections: (id, result, status) ->
    meters = result.routes[0].legs[0].distance.value
    dest = result.routes[0].legs[0].end_address
    if parseInt(meters) > 0
      $("#rail_miles").val($("#rail_miles").val() + id + ":" + meters + "|")
      $("#dest_detail").html(dest).removeClass('red')
      $("#dest_address").val(dest)
    CustomerQuote.verifyRailMiles()

  requestDirectionsError: (id, result, status) ->
    $("#dest_detail").html("Invalid Zip").addClass('red')

  initSelections: ->
    port = $("#port").val()
    csize = $("#csize").val()
    $("#port").trigger "change"  unless $.isBlank(port)
    $("#csize").trigger "change"  unless $.isBlank(csize)
    return

  ajaxLoadForm: ->
    matches = document.URL.match(/hub=(.*)$/)
    if $('.ajax-load-quote').exists()
      params = {}
      params['hub'] = matches[1] if matches
      $.ajax
        url: '/quote_engines/new'
        dataType: 'script'
        type: 'GET'
        data: $.param(params)

$ ->
  CustomerQuote.ajaxLoadForm()