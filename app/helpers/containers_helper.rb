module ContainersHelper
  include ContainerChargesHelper

  def has_right_to_lock?
    @has_right_to_lock||= accessible?('containers', 'lock')
  end

  def has_right_to_unlock?
    @has_right_to_unlock||= accessible?('containers', 'unlock')
  end

  def lock_checkbox(container, ajax: false, reload: false)
    has_right = container.lock?&&has_right_to_unlock? || !container.lock?&&has_right_to_lock?
    return unless has_right
    content_tag(:label, class: 'lock-checkbox') do
      options = { class: 'lock-container', data: {} }
      options[:data].merge!(ajax: true) if ajax
      options[:data].merge!(reload: true) if reload
      check_box_tag(:lock, container.id, container.lock?, options) + content_tag(:span)
    end
  end

  def build_trackshipment_url
    session[:container_selectors]||= []
    selectors = session[:container_selectors]
    case true
    when selectors.empty?
      nil
    else
      web_shipments_url(id: selectors.join(','))
    end
  end

  def location_for_drivers(container)
    container.truckers.uniq.map do |trucker|
      location = trucker.locations.last
      ["#{location.try(:timestamp).try(:us_datetime)}: #{trucker.name}", location.try(:id), disabled: location.nil?]
    end
  end

end
