module ApplicantsHelper

  def customized_field_options(field, attrs)
    label = field.to_s.titleize
    type = attrs.type rescue :string
    required = attrs.required rescue false
    wrapper = [:boolean].include?(type)  ? :default : :vertical
    klass = attrs.klass rescue nil
    options = attrs.options.map(&:to_s).map do |val|
      [val.titleize, val]
    end rescue nil
    opts = { as: type, label: label, wrapper: wrapper, required: required, input_html: { class: 'itext' } }
    opts.merge!(collection: options.map) if options
    opts
  end
end
