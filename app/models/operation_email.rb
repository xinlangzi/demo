require 'render_anywhere'
class OperationEmail < ApplicationRecord
  include RenderAnywhere
  has_many :set_date_operations, class_name: 'OperationType', foreign_key: 'set_date_email_id'
  has_many :remove_date_operations, class_name: 'OperationType', foreign_key: 'reset_date_email_id'
  validates :name, presence: true, uniqueness:  true
  validates :subject, :content, presence: true
  validates :status_title, presence: true

  default_scope { order("name ASC") }

  KEYWORDS = {
    "$order_progress" => "Order Progress Bar",
    "$status_title" => "Order Status Title",
    "$user" => "Trucker/Customer Name",
    "$operation_name" => "Operation Name",
    "$operation_date" => "Operation Date/DateTime",
    "$company_name" => "Company Name",
    "$company_address" => "Company Address",
    "$company_street" => "Company Street",
    "$company_city_state_zip" => "Company City, State, Zip",
    "$container_id" => "Container ID",
    "$container_no" => "Container No.",
    "$container_weight" => "Container Weight",
    "$container_commodity" => "Container Commodity",
    "$container_size" => "Container Size/Type",
    "$container_reference_no" => "Container Reference No.",
    "$container_last_lfd" => "Container Last Free Day",
    "$container_terminal_eta" => "Container Terminal/Rail ETA",
    "$container_ssline_bl_no" => "Container SS Line B/L No.*",
    "$container_pickup_no" => "Container Pickup No.",
    "$container_ssline_booking_no" => "Container SS Line Booking No.",
    "$container_early_receiving_date" => "Container Early Receiving Date",
    "$container_rail_cutoff_date" => "Container Rail Cutoff Date",
    "$container_empty_release_no" => "Container Empty Release No.",
    "$container_link" => "Container Link",
    "$tracking_link" => "Track Shipment Link"
  }

  def send_email(recipient, id)
    operation = Operation.find(id)
    subject = build_email_subject(recipient, operation)
    content = build_email_content(recipient, operation)
    OperationMailer.delay_for(10.seconds).notify_when_operated_date_is_changed(recipient.id, operation.id, {subject: subject, content: content})
  end

  def build_email_subject(recipient, operation)
    convert_keywords(self.subject, recipient, operation)
  end

  def build_email_content(recipient, operation)
    html = Slim::Template.new(){content}.render
    convert_keywords(html, recipient, operation)
  end

  def convert_keywords(origin, user, operation)
    container = operation.container
    operation_type = operation.operation_type
    origin.gsub!('$status_title', status_title || '')
    origin.gsub!('$user', user.name)
    origin.gsub!('$container_id', container.id.to_s)
    origin.gsub!('$container_no', container.container_no.to_s)
    origin.gsub!('$container_size', container.size.to_s)
    origin.gsub!('$container_weight', "#{container.weight_decimal_humanized} LBS")
    origin.gsub!('$container_commodity', container.commodity.to_s)
    origin.gsub!('$operation_name', operation_type.name.to_s)
    origin.gsub!('$operation_date', operation.view_operated_at.to_s)
    origin.gsub!('$company_name', operation.company.name.to_s)
    origin.gsub!('$company_address', operation.company.address.to_s)
    origin.gsub!('$company_street', operation.company.address_street.to_s)
    origin.gsub!('$company_city_state_zip', operation.company.city_state_zip.to_s)
    origin.gsub!('$container_reference_no', container.reference_no.to_s)
    origin.gsub!('$container_pickup_no', container.pickup_no.to_s)
    #import
    origin.gsub!('$container_last_lfd', container.rail_lfd.to_s)
    origin.gsub!('$container_ssline_bl_no', container.ssline_bl_no.to_s)
    origin.gsub!('$container_terminal_eta', container.terminal_eta.to_s)

    #export
    origin.gsub!('$container_ssline_booking_no', container.ssline_booking_no.to_s)
    origin.gsub!('$container_pickup_no', container.pickup_no.to_s)
    origin.gsub!('$container_early_receiving_date', container.early_receiving_date.to_s)
    origin.gsub!('$container_rail_cutoff_date', container.rail_cutoff_date.to_s)
    origin.gsub!('$container_empty_release_no', container.empty_release_no.to_s)


    host = ActionMailer::Base.default_url_options[:host]
    protocol = ActionMailer::Base.default_url_options[:protocol]
    url_helpers = Rails.application.routes.url_helpers

    container_link = url_helpers.container_url(container, host: host, protocol: protocol)
    origin.gsub!('$container_link', container_link)

    tracking_link = url_helpers.web_shipments_url(id: container.uuid, host: host, protocol: protocol)
    origin.gsub!('$tracking_link', tracking_link)

    html = render(partial: 'order_mailer/containers/progress.html.slim', locals: { container: container })
    origin.gsub!('$order_progress', html)

    origin
  end
end
