#encoding: utf-8
module ApplicationHelper
  include FontAwesome::Rails::IconHelper
  include MobilesHelper
  include DriversHelper

  def outlook_font
    "font-family: Helvetica, Arial, sans-serif;"
  end

  def numeric_to_filter(num)
    "#{number_to_currency(num, delimiter: '')}|#{number_to_currency(num)}".gsub(/\$/, '')
  end

  def enum_options(enum, use_integer: false)
    enum.map{|k, v| [k.titleize, (use_integer ? v.to_s : k)] }
  end

  def uploader_image_tag(uploader, options={})
    if params[:online]
      image_tag(uploader.url, options)
    else
      # PDF generate process: 1. Use absolutely path for file system 2. Use url for remote storage
      if uploader.send(:storage).is_a?(CarrierWave::Storage::File)
        wisepdf_image_tag(uploader.path, options)
      else
        image_tag(uploader.url, options)
      end
    end
  end

  def address_sequences(companies, actions)
    content_tag(:ul, class: 'address-label') do
      companies.zip(actions).map do |company, action|
        content_tag :li do
          "<label class='gray-label'>#{action}</label><label>#{company.name}</label><div>#{company.address}</div>".html_safe
        end
      end.join('').html_safe
    end
  end

  def mileage_sequences(mileages)
    content_tag('ul') do
      mileages.map do |mileage|
        concat(content_tag(:li, mileage))
      end
    end
  end

  def calendar_for(object, method, options={})
    time_required = object.send("time_required_on_#{method.to_s}?") rescue false
    ymdhm = object.send(method.to_sym).to_datetime.send(time_required ? :ymdhm : :ymd) rescue nil
    error = object.errors.full_messages_for(method.to_sym).join('')
    ymdhm = appt_range(object, true) if method.to_s == 'appt_date'# hard code here
    data = { id: object.id, method: method.to_s, klass: object.class.to_s, 'embed-ajax-url' => options['embed-ajax-url'] }
    input_class = time_required ? 'ajax-datetime-picker' : 'ajax-date-picker'
    if current_user.is_admin?
      inner_tags = []
      unless options[:disabled]
        inner_tags << fields_for(object){|i| i.text_field method, value: ymdhm, class: "only-icon cal-icon #{input_class}", id: dom_id(object, method), data: data}
        inner_tags << link_to('', '/datepickers/' + object.id.to_s + "?klass=#{object.class.to_s}&method=#{method.to_s}&embed-ajax-url=#{options['embed-ajax-url']}" , method: :delete, remote: true, class: 'fa fa-times-circle') unless ymdhm.blank?
      end
      inner_tags << content_tag('span', ymdhm, class: 'bold') if ymdhm
      inner_tags << approve_alter_request_link(object, method) rescue nil
      inner_tags << content_tag('div', error, class: 'red') if error
      content_tag('span', id: dom_id(object, "#{method}-data-picker")){ inner_tags.compact.inject(:+) }
    else
      content_tag('div', ymdhm, class: 'bold')
    end
  end

  def find_cached_alter_request(target, name)
    (@alter_requests||= AlterRequest.all).detect do |ar|
      (ar.alter_requestable_id == target.id) &&
      (ar.attr == name.to_s) &&
      (ar.alter_requestable_type == target.class.base_class.to_s)
    end
  end

  def approve_alter_request_link(target, name)
    if object = find_cached_alter_request(target, name)
      link_to('', "/alter_requests/#{object.id}/approve", method: :put, remote: true, id: dom_id(object, 'approve'), class: 'alter-request', data: { confirm: "Are you sure to approve this alter request?" })
    end
  end

  #BEGIN customized container operation
  def calendar_for_operation(operation)
    ymdhm = operation.view_operated_at
    inner_tags = []

    inner_tags << fields_for(operation) do |i|
      options = {
        value: ymdhm,
        class: 'only-icon cal-icon operation-at',
        id: nil,
        data: {
          time_required:  operation.time_required?,
          url: operate_operation_path(operation)
        }
      }
      options[:data][:confirm] = 'Are you sure you want to set date on the behalf of the driver?' if operation.delivery_mark?
      i.text_field :operated_at, options
    end if current_user.is_admin?&&!operation.lock?

    unless ymdhm.blank?
      inner_tags << link_to('', "/operations/#{operation.id}/cancel_operate", method: :delete, remote: true, class: 'fa fa-times-circle') if current_user.is_admin?&&!operation.lock?
      inner_tags << content_tag('span', ymdhm, class: 'bold')
      inner_tags << approve_alter_request_link(operation, :operated_at)
    end
    inner_tags << content_tag('div', operation.errors[:base].join('') , class: 'error') unless operation.errors[:base].empty?
    content_tag('div', class: dom_id(operation, 'operate')){ inner_tags.inject(:+) }
  end

  def attachments_for(imagable, column_name=nil, uploader: true)
    if imagable
      li_tags = []
      images = imagable.images
      images = images.where(column_name: column_name) if column_name
      images.each_with_index do |image, index|
        class_names = ['num']
        class_names << image.status
        class_names << 'pod' if image.pod?
        li_tags << content_tag('li', class: class_names.join(' ')) do
          url = image_path(image)
          link_to(index+1, 'javascript: void(0)', onClick: "javascript:App.newPopup('#{url}', 'ViewDocument', 800, 650, 0, 0)")
        end
      end
      if current_user.is_admin? && uploader
        li_tags << content_tag('li', class: 'upload') do
          url = new_image_path(Image.new, image: { imagable_type: imagable.class.table_name.classify, imagable_id: imagable.id, column_name: column_name })
          link_to('javascript: void(0)', onClick: "javascript:App.newPopup('#{url}', 'ViewDocument', 800, 650, 0, 0)") do
            fa_icon("upload")
          end
        end
      end
      content_tag('ul', class: "docs #{dom_id(imagable, 'docs')}"){ li_tags.inject(:+) }.html_safe
    end
  end

  def driver_status(operation)
    inner_tags = []
    inner_tags << link_to('', "/drivers/cancel?iid=#{operation.id}", remote: true, class: 'fa fa-times-circle') if current_user.is_admin?&&operation.driver_cancelable?
    inner_tags << content_tag('span', operation.trucker) if current_user.is_admin? && operation.trucker
    inner_tags << content_tag('div', operation.errors[:assign].join('') , class: 'red')
    content_tag('div', class: dom_id(operation, 'driver')){ inner_tags.inject(:+) }.html_safe
  end

  def email_status(operation)
    inner_tags = []
    if operation.trucker_id
      inner_tags << link_to('', "/operations/#{operation.id}/notify", remote: true, class: 'icons-to-mail icon16', title: 'click to send email') if current_user.is_admin?&&operation.notifiable?
      inner_tags << content_tag('span', nil, class: 'icons-mail-sent icon16', title: 'Sent already') if operation.notified?
      inner_tags << content_tag('div', operation.errors[:notify].join('') , class: 'red')
    end
    content_tag('div', class: dom_id(operation, 'email')){ inner_tags.inject(:+) }.html_safe
  end

  def random_id(mark=nil)
    "#{mark.to_s}-#{rand(10**6)}"
  end

  def tab_abbrev
    case "#{controller.controller_path}:#{controller.action_name}"
    when /vacations\:.*/i
      "vac"
    when /^report\/.*\:.*/
      "rpt"
    when /.*containers\:.*calendar/i
      "cal"
    when /.*containers\:pre_alerts/i
      "pa"
    when /.*containers\:(monthly_volume|daily_volume)/i
      "mv"
    when /.*containers\:(new|create)/i
      "ctn"
    when /.*containers\:open/i
      "cto"
    when /.*containers\:edi$/i, /edi_logs\:.*/i
      "edi"
    when /.*containers\:.*/i
      "ct"
    when /support\:.*/i
      "sp"
    when /messaging\:.*/i
      "msg"
    when /.*(financials|reconciliations|charges|categories)\:.*/i
      "fin"
    when /.*(invoices|adjustments)\:.*/i
      "inv"
    when /.*payments\:.*/i
      "pym"
    when /.*shippers\:.*/i
      "sip"
    when /.*consignees\:.*/i
      "con"
    when /.*(customers|truckers)\:.*/i
      "com"
    when /.*depots\:.*/i
      "dep"
    when /.*daily_mileages\:.*/i
      "dma"
    when /users:profile/i
      ""
    else
      "set"
    end
  end

  def checkmark(truthy, text=nil)
    content_tag("i", text, class: 'fa fa-check-circle green') if truthy
  end

  def button_name(obj)
    obj.new_record? ? 'Create' : 'Update'
  end

  def restrict_to(condition)
    yield if condition&&block_given?
  end

  def array_options(array, zero=false)
    array.each_with_index.collect{|a,index| [a,index+(zero ? 0 : 1)]}
  end

  def objects_for_select(objects)
    objects.blank? ? [] : objects.map{|o| [o.name, o.id]}
  end

  # Outputs a page title appropriate for the page: suitable for the <title> tag or for <h1> in the content
  def title
    @title || "#{controller_name.humanize.titleize} - #{controller.action_name.to_s.humanize}"
  end

  def appt_range(container, display_date=false)
    if container.appt_date.present?
      date = display_date ? container.appt_date.strftime("%F ") : ""
      if container.appt_start.present?
        if container.appt_end.blank?
          date += Container.format_time(container.appt_start)
        else
          date = date + "<br/>btwn " + Container.format_time(container.appt_start) + " and " + Container.format_time(container.appt_end)
        end
      end
      date.html_safe
    else
      ""
    end
  end

  def no_action?(name)
    yield if block_given? && Array(name).flatten.exclude?(controller.action_name)
  end

  def print_status?
    ['print', 'email', 'email_all', 'emailx'].include?(controller.action_name)
  end

  def save_or_update(obj)
    obj.new_record? ? "Create" : "Update"
  end

  def inactive_tip(obj)
    return if obj.nil?
    content_tag('sup', 'inactive', class: 'red italic f80') unless obj.active?
  end

  # jordan's small functions
  def ctrl_in?(*ctrls)
    ctrls.flatten.include?(controller.controller_name)
  end

  def show_reference_no(invoices=[])
    @show_reference_no||=!invoices.detect{|invoice| ['ReceivableInvoice'].include?(invoice.type)}.nil?
  end

  def simple_errors_for(object, message=nil)
    html = ""
    unless object.errors.blank?
      html << "<ul class='error-recap red'>"
      object.errors.full_messages.uniq.each do |error|
        html << "<li>#{error}</li>"
      end
      html << "</ul>"
    end
    html.html_safe
  end

  def errors_for(object, message=nil)
    html = ""
    unless object.errors.blank?
      html << "<div class='formErrors #{object.class.name.humanize.downcase}Errors'>\n"
      if message.blank?
        if object.new_record?
          html << "\t\t<h5>There was a problem creating the #{object.class.name.humanize.downcase}</h5>\n"
        else
          html << "\t\t<h5>There was a problem updating the #{object.class.name.humanize.downcase}</h5>\n"
        end
      else
        html << "<h5>#{message}</h5>"
      end
      html << "\t\t<ul>\n"
      object.errors.full_messages.uniq.each do |error|
        html << "\t\t\t<li>#{error}</li>\n"
      end
      html << "\t\t</ul>\n"
      html << "\t</div>\n"
    end
    html.html_safe
  end

  def has_quickbooks_integration?
    !! cowner.quickbooks_integration
  end

end


# The below is from https://github.com/rspec/rspec-rails/issues/476#issuecomment-4705454
# Needed if we want to use threadsafe! in rails 3.2
class ActionView::Helpers::FormBuilder
  def error_messages
    return unless object.respond_to?(:errors) && object.errors.any?

    errors_list = ""
    errors_list << @template.content_tag(:span, "There are errors!", :class => "title-error")
    errors_list << object.errors.full_messages.uniq.map { |message| @template.content_tag(:li, message) }.join("\n")

    @template.content_tag(:ul, errors_list.html_safe, :class => "error-recap round-border")
  end
end
