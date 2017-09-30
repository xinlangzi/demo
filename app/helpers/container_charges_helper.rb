module ContainerChargesHelper
  # returns a select tag that wraps up the options given in option_group_from_collection_for_select
  # also includes the options for disabled and include_blank
  # to-remove
  # def select_with_option_groups(object, key, method, choices, options = {}, html_options = {})
  #   classes = ['chosen-select']
  #   classes << html_options[:class]
  #   enabled_disabled_option = html_options.has_key?(:disabled) && html_options[:disabled] == true ? "disabled=disabled" : ""
  #   include_or_not_blank = options.has_key?(:include_blank) && options[:include_blank] == true ? "<option value=\"\"></option>" : ""
  #   html = "<select class=\"#{classes.join(' ')}\" id=\"#{object}_#{key}_#{method}\" name=\"#{object}[#{key}][#{method}]\" #{enabled_disabled_option}>"
  #   html += include_or_not_blank # inserts an empty option value into options array
  #   html += choices
  #   html += "</select>"
  # end

end
