class SearchParams
  DEFAULT_SHIPPER_FIELD = 'Enter Shipper'
  DEFAULT_CONSIGNEE_FIELD = 'Enter Consignee'
  DEFAULT_CITY_FIELD = 'Enter city'

  DEFAULT_MAPPINGS = {
    "consignee_address_city_like"=> DEFAULT_CITY_FIELD,
    "shipper_address_city_like"=> DEFAULT_CITY_FIELD,
    "consignee_name_like" => DEFAULT_CONSIGNEE_FIELD,
    "shipper_name_like" => DEFAULT_SHIPPER_FIELD
  }
  def self.filter_search_container_params(params)
    lambda{
      DEFAULT_MAPPINGS.each do |key, value|
        params.delete(key) if params[key]&&params[key].gsub(/#{value}/,'').blank?
      end
    }.call rescue return

  end

end