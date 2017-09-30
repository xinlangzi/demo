window.GoogleMap =

  loadScript: (key, callbackfn)->
    if window.google && google.maps
      window.eval(callbackfn + "()")
    else
      script = document.createElement('script')
      script.type = 'text/javascript'
      if key
        script.src = 'https://maps.googleapis.com/maps/api/js?language=en&region=US&key=' + key + '&callback=' + callbackfn
      else
        script.src = 'https://maps.googleapis.com/maps/api/js?language=en&region=US&callback=' + callbackfn
      document.body.appendChild script
