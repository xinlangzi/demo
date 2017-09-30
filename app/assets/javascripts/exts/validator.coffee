# Validation Definition
$.validator.addClassRules "gte0",
  gte0:
    elements: ".gte0"

$.validator.addClassRules "zipcode",
  zipcode:
    elements: ".zipcode"

$.validator.addClassRules "emails",
  emails:
    elements: ".emails"

$.validator.addMethod "gte0", ((value, element, param) ->
  parseFloat(value) >= 0
), "must >= 0"

$.validator.addMethod "zipcode", ((value, element, param) ->
  /^\s*\d{5}\s*$/.test(value)
), "5-Digit rquired"

$.validator.addMethod "emails", ((value, element, params) ->
  valid = true
  unless @optional(element)
    valid&&=$.validator.methods.email.call(this, $.trim(email), element) for email in value.split(/[;,]+/)
  valid
), "Use a comma or semicolon to separate multiple email addresses."