class Worker::UpdateFuelPrice
  def self.perform
    Hub.with_default.find_each do |hub|
      fuel_zone = hub.fuel_zone || 'U.S.'
      doc = Nokogiri::HTML(open(Fuel::FUEL_URL))
      fuel_zone_node = doc.at_css(".DataRow .DataStub1[text()='#{fuel_zone}']")
      raise 'Invalid Fuel Zone' if fuel_zone_node.nil?
      price = fuel_zone_node.parent.parent.parent.parent.at_css('.Current2').text
      Fuel.save_price(hub, price)
    end
  end
end
