class DriverMailerPreview < ActionMailer::Preview

  def contact
    info = { 'name'=> 'John', 'email'=> 'john@test.com'}
    DriverMailer.contact(info)
  end

  def quotes
    rr = Port.first.rail_roads.first
    info = { 'name'=> 'John', 'email'=> 'john@test.com'}
    options = [{
      'rail_road_id'=> rr.id.to_s,
      'destination'=> 'Center, Trego, WI, United States',
      'miles'=> '20'
    }]
    DriverMailer.quotes(info, options)
  end
end