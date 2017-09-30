class DatetimePickerInput < SimpleForm::Inputs::DateTimeInput
  def input(wrapper_options)
    value = @builder.object.send(attribute_name)
    input_html_options[:value] = value.to_s
    @builder.text_field(attribute_name, merge_wrapper_options(input_html_options, wrapper_options))
  end
end