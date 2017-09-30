module SslinesHelper

  def detailed_column_list
    list = super
    list.insert(3, 'Rail Billing Email', ->(c){ c.split_email(:rail_billing_email).map{|mail| mail_to(mail)}.join(", ").html_safe })
    list.insert(4, 'EQ Team Email', ->(c){ c.split_email(:eq_team_email).map{|mail| mail_to(mail)}.join(", ").html_safe })
    list["Free Per Diem Days"] = ->(c){ render partial: 'free_outs', object: c.free_outs}
    list
  end

  def column_list
    list = super
    list["Depots"] = ->(c){ h c.depots.count }
    list["Chassis Fee"] = lambda { |company|
        fields_for :company, company do |c|
          c.text_field :chassis_fee, class: "w80 center auto-save nospace", id: "chassis_fee_fee_#{company.id}", ref: "#{company.class.to_s}:#{company.id}:chassis_fee"
        end
     }
    list
  end

end
