window.BaseRate =

  init: ->
    BaseRate.tabs()

  events: ->
    BaseRate.removeRow()
    BaseRate.onTab()

  removeRow: ->
    $(document).on 'click', '.remove-row', ->
      $(this).closest('tr').remove()

  onTab: ->
    $(document).on 'click', '#base-rate-tabs ul li a', ->
      window.dispatchEvent(new Event('resize'));

  tabs: ->
    $('#base-rate-tabs').tabs()

  loadChartData: (hub_id)->
    BaseRate.chart(hub_id)

  chart: (id)->
    selector = '#hub_' + id + ' .d3-chart'
    if $(selector).length > 0
      $(selector).html('<center>Loading chart</center>')
      nv.addGraph
        generate: ->
          chart = nv.models.lineChart().useInteractiveGuideline(true)
          chart.xAxis.axisLabel('Miles').tickFormat d3.format(',r')
          chart.yAxis.axisLabel('Rate($)').tickFormat d3.format(',r')
          d3.json '/base_rates.json?hub_id=' + id, (json) ->
            $(selector).html('')
            d3.select(selector)
              .append('svg')
              .datum(json)
              .transition()
              .duration(500)
              .call(chart)
            return
          nv.utils.windowResize ->
            d3.select(selector + ' svg').call(chart)
          chart
        callback: (chart) ->
          tooltip = chart.interactiveLayer.tooltip;
          tooltip.contentGenerator (d)->
            template = Hogan.compile('<table><thead><tr><td colspan="4"><strong class="x-value">{{value}}</strong></td></tr></thead><tbody>{{#series}}<tr><td class="legend-color-guide"><div style="background-color:{{color}};"></div></td><td class="key">{{key}}</td><td class="value">${{value}}</td><td>(${{data.profit}})</td></tr>{{/series}}</tbody></table>')
            template.render({value: d.value, series: d.series });
          chart

BaseRate.events()

$(document).on 'turbolinks:load', ->
  BaseRate.init()
