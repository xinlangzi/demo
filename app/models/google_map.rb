require "open-uri"
class GoogleMap

  TIME = 1
  CHICAGO = [41.850033, -87.6500523]
  US_ADDRESS = /\A(.*)\, (.*)\, ([[:upper:]]{2}) (\d+), USA\Z/

  STATUS_CODES = {
    "OK" => "indicates that no errors occurred; the address was successfully parsed and at least one geocode was returned.",
    "NOT_FOUND" => "indicates at least one of the locations specified in the request's origin, destination, or waypoints could not be geocoded.",
    "MAX_WAYPOINTS_EXCEEDED" => "indicates that too many waypointss were provided in the request The maximum allowed waypoints is 8, plus the origin, and destination.",
    "ZERO_RESULTS" => "indicates that the geocode was successful but returned no results. This may occur if the geocoder was passed a non-existent address.",
    "OVER_QUERY_LIMIT" => "indicates that you are over your quota.",
    "REQUEST_DENIED" => "indicates that your request was denied.",
    "INVALID_REQUEST" => "generally indicates that the query (address, components or latlng) is missing.",
    "UNKNOWN_ERROR" => "indicates that the request could not be processed due to a server error. The request may succeed if you try again."
  }

  class Location
    attr_accessor :address, :lng, :lat
    def initialize(options={})
      options.each{|k,v| instance_variable_set("@#{k.to_s}", v)}
    end
  end

  def self.api_key(type)
    case type
    when :frontend
      SystemSetting.first.try(:google_map_api_key_frontend)
    when :backend
      SystemSetting.first.try(:google_map_api_key_backend)
    else
      raise "Please provide type for google map key!"
    end
  end

  def self.image_url(address, width: 500, height: 300)
    "http://maps.googleapis.com/maps/api/staticmap?center=#{address}&zoom=10&scale=false&size=#{width}x#{height}&maptype=roadmap&format=png&visual_refresh=true&markers=size:mid|color:0xff0000|label:1|#{address}"
  end

  def self.matrix_distances(origins, dests)
    # https://developers.google.com/maps/documentation/distancematrix/#Limits
    origins = origins.join("|").gsub(/\s+/,' ')
    dests = dests.join("|").gsub(/\s+/,' ')
    values = [CGI::escape(origins),CGI::escape(dests), GoogleMap.api_key(:backend)]
    url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=%s&destinations=%s&mode=driving&language=en&region=us&sensor=true&key=%s"%values
    Rails.logger.info("-->Request URL: " + url)
    ret = nil
    3.times do
      begin
        data = URI.parse(url).read
        json = JSON.parse(data)
        status_code = json["status"]
        case status_code
        when "OK"
          rows = json["rows"]
          ret = rows.map do |row|
            elements = row["elements"]
            elements.map do |element|
              element["distance"]["value"] rescue nil
            end
          end
        else
          SystemLog.create(name: "Google Matrix Distance Query", description: "(#{status_code}) URL: #{url}")
        end
        return ret
      rescue => ex
        Rails.logger.info(ex.message)
        sleep(2)
      end
    end
    ret
  end

  def self.distance(from, to, random=Rails.env.test?)
    return rand(10**5) if random
    from.gsub!(/\s+/, ' ')
    to.gsub!(/\s+/, ' ')
    values = [CGI::escape(from),CGI::escape(to), GoogleMap.api_key(:backend)]
    url = "https://maps.googleapis.com/maps/api/directions/json?origin=%s&destination=%s&region=us&sensor=true&key=%s"%values
    ret = nil
    Rails.logger.info("-->Request URL: " + url)
    3.times do
      begin
        data = URI.parse(url).read
        json = JSON.parse(data)
        status_code = json["status"]
        case status_code
        when "OK"
          return json["routes"][0]["legs"][0]["distance"]["value"].to_i
        when "NOT_FOUND", "ZERO_RESULTS", "OVER_QUERY_LIMIT"
          SystemLog.create(name: "Google Directions Query", description: "#{status_code}: #{STATUS_CODES[status_code]}(#{from}->#{to}) URL: #{url}")
          return ret
        else
          SystemLog.create(name: "Google Directions Query", description: "#{status_code}: #{STATUS_CODES[status_code]}(#{from}->#{to}) URL: #{url}")
        end
      rescue => ex
        Rails.logger.info(ex.message)
        sleep(1)
      end
    end
    ret
  end

  def self.geocode_to_json(address)
    return nil if address.blank?
    time = 0.2
    while(time <= TIME)
      begin
        Net::HTTP.start('maps.googleapis.com') do |http|
          http.read_timeout = time
          Rails.logger.info(">>>>>>>Get address from GoogleMap: #{time}...#{address}")
          response = http.get("/maps/api/geocode/json?address=%s&region=us"%CGI::escape(address))
          return JSON.parse(response.body)
        end
      rescue => ex
        Rails.logger.info(ex.message)
        time+=0.2
      end
    end
  end

  def self.geocode(address)
    locations = []
    json = geocode_to_json(address)
    if json&&json["status"] == "OK"
       json["results"].each do |result|
        formatted_address = result["formatted_address"].to_s.strip
        if US_ADDRESS.match(formatted_address)
          location = result["geometry"]["location"] rescue nil
          locations << Location.new({ address: formatted_address, lat: location["lat"].round(6), lng: location["lng"].round(6) }) if location
        end
      end
    end
    locations.compact
  end

  # def self.header
  #   '<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?language=en&region=US"></script>'
  # end

  def self.show(namespace=nil)
    "<script type=\"text/javascript\">#{init_script(namespace)}</script>"
  end

  def self.init_script(namespace)
<<JS
var directionsDisplay = new google.maps.DirectionsRenderer();
var directionsService = new google.maps.DirectionsService();
var chicago = new google.maps.LatLng(#{CHICAGO[0]}, #{CHICAGO[1]});
var myOptions = {
  zoom:7,
  mapTypeId: google.maps.MapTypeId.ROADMAP,
  center: chicago
}
var map = new google.maps.Map(document.getElementById('map'), myOptions);
var namespace = '#{namespace}';
directionsDisplay.setMap(map);
function requestRoutes(from, to, id, times){
  directionsService.route({
    origin: from,
    destination: to,
    travelMode: google.maps.DirectionsTravelMode.DRIVING, region: 'us'}, function(result, status){
      if(status==google.maps.DirectionsStatus.OK){
        var directionsRenderer = new google.maps.DirectionsRenderer();
        directionsRenderer.setMap(map);
        directionsRenderer.setDirections(result);
        if(namespace.length > 0){
          window[namespace].loadedDirections(id, result, status);
        }
      }else{
        if(times==5){
          if(namespace.length > 0){
            window[namespace].requestDirectionsError(id, result, status);
          }
        }else{
          setTimeout(function(){requestRoutes(from, to, id, times+1);}, 1500);
        }
      }
  });
}
function clearDirections(){
  map = new google.maps.Map(document.getElementById('map'), myOptions);
  directionsDisplay.setMap(map);
}
JS
  end

  #'41.786579,-87.676547'
  #'525 Marie Dr, South Holland, IL'
  def self.request_directions(from, to, id)
<<JS
requestRoutes('#{from}', '#{to}', '#{id}', 1);
JS
  end

  def self.clear_directions
<<JS
clearDirections();
JS
  end
end
