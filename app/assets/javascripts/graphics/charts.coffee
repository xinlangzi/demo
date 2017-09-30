window.Chart =

  init: ->
    Chart.monthlyVolume()
    Chart.dailyVolume()
    Chart.mileages()

  monthlyVolume:->
    params = window.location.search.replace( "?", "")
    if $('#monthly-chart:not(.inited)').exists()
      $('#monthly-chart').addClass('inited')
      nv.addGraph ->
        chart = nv.models.multiBarChart().stacked(true)

        d3.json "/containers/monthly_volume.json?#{params}", (json) ->
          d3.select('#monthly-chart')
            .append('svg')
            .datum(json.containers)
            .transition()
            .duration(500)
            .call(chart)

        nv.utils.windowResize ->
          d3.select('#monthly-chart svg').call(chart)

        return chart

  dailyVolume: ->
    params = window.location.search.replace( "?", "")
    if $('#daily-chart:not(.inited)').exists()
      $('#daily-chart').addClass('inited')
      nv.addGraph ->
        chart = nv.models.multiBarChart().stacked(true)

        d3.json "/containers/daily_volume.json?#{params}", (json) ->
          d3.select('#daily-chart')
            .append('svg')
            .datum(json.containers)
            .transition()
            .duration(500)
            .call(chart)

        nv.utils.windowResize ->
          d3.select('#daily-chart svg').call(chart)

        return chart
  mileages: ->
    params = window.location.search.replace( "?", "")
    if $('#mileages-chart:not(.inited)').exists()
      $('#mileages-chart').addClass('inited')
      nv.addGraph ->
        chart = nv.models.discreteBarChart().showValues(true)
        chart.xAxis.axisLabel('Miles').tickFormat d3.format(',r')
        chart.yAxis.axisLabel('Count').tickFormat d3.format(',r')
        chart.valueFormat(d3.format('d'))

        d3.json "/containers/mileages.json?#{params}", (json) ->
          d3.select('#mileages-chart')
            .append('svg')
            .datum(json.mileages)
            .transition()
            .duration(500)
            .call(chart)

        nv.utils.windowResize ->
          d3.select('#mileages-chartsvg').call(chart)

        return chart

$(document).on 'turbolinks:load', ->
  Chart.init()