class ExpirationMailer < MailerBase

  # def notify_trucker_expiring(trucker, truck, date_field, days_prior_exp, doc)
  #   subject = "Your #{doc} is expiring #{days_prior_exp}"
  #   @trucker = trucker
  #   @expiration_date = date_field
  #   @doc = doc
  #   @time_left = days_prior_exp
  #   @truck = truck
  #   @owner = Owner.first
  #   mail(
  #     from: Owner.first.email,
  #       to: CheckEmail.filter(trucker),
  #  subject: subject
  #   )
  # end

  # def notify_admin_expiring(object_class, trucker_or_truck_list, date_field, doc)
  #   subject = "Expiring #{doc.pluralize}"
  #   @list = trucker_or_truck_list
  #   @object_class = object_class
  #   @doc = doc
  #   @date_field = date_field
  #   @owner = Owner.first
  #   mail(
  #     from: Owner.first.email,
  #       to: CheckEmail.filter(Owner.first),
  #  subject: subject
  #   )
  # end
end
