window.SwiperSlide =

  init: ->
    F7H.app.swiper '#stops .swiper-container:not(.inited)',
      pagination: '#stops .swiper-pagination'
      spaceBetween: 50
    $('#stops .swiper-container').addClass('inited')

    F7H.app.swiper '#paycheck .swiper-container:not(.inited)',
      pagination: '#paycheck .swiper-pagination'
    $('#paycheck .swiper-container').addClass('inited')

    F7H.app.swiper '#j1s-tab1 .swiper-container:not(.inited)',
      pagination: '#j1s-tab1 .swiper-pagination'
    $('#j1s-tab1 .swiper-container').addClass('inited')

    F7H.app.swiper '#maintenance .swiper-container:not(.inited)',
      pagination: '#maintenance .swiper-pagination'
    $('#maintenance .swiper-container').addClass('inited')

    Dom7('#j1s-tab2').on 'show', ->
      F7H.app.swiper '#j1s-tab2 .swiper-container:not(.inited)',
        pagination: '#j1s-tab2 .swiper-pagination'
      $('#j1s-tab2 .swiper-container').addClass('inited')

    Dom7('#j1s-tab3').on 'show', ->
      F7H.app.swiper '#j1s-tab3 .swiper-container:not(.inited)',
        pagination: '#j1s-tab3 .swiper-pagination'
      $('#j1s-tab3 .swiper-container').addClass('inited')

    Dom7('#profile-tab2').on 'show', ->
      F7H.app.swiper '#profile-tab2 .swiper-container:not(.inited)',
        pagination: '#profile-tab2 .swiper-pagination'
      $('#profile-tab2 .swiper-container').addClass('inited')

$ ->
  SwiperSlide.init()
