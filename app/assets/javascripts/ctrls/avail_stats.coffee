# window.AvailStats =
#   init: ->
#     AvailStats.load()
#
#   load: ->
#     if $('.tiny-avail-stats:not(.inited)').length > 0
#       AvailStats.reload()
#
#   reload: ->
#     $.ajax
#       url: '/avail_stats'
#       type: 'GET'
#
# # $(document).on 'turbolinks:load', ->
# #   AvailStats.init()
