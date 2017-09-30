module ParamsToPermit
  extend ActiveSupport::Concern

  def container_params
    attrs = [
      :vid, :admin_comment, :appt_date, :appt_start, :appt_end, :appt_is_range,
      :chassis_comment, :chassis_no, :commodity, :customer_comment,
      :chassis_pickup_company_id, :chassis_pickup_with_container, :chassis_return_with_container, :chassis_return_company_id,
      :container_no, :container_size_id, :container_type_id, :customer_id, :customers_employee_id,
      :early_receiving_date, :empty_release_no,
      :haz_cargo, :house_bl_no, :house_booking_no, :per_diem_lfd, :pickup_no, :public_comment,
      :rail_cutoff_date, :rail_lfd, :reference_no,
      :seal_no, :ssline_bl_no, :ssline_booking_no, :ssline_id, :terminal_eta, :to_save, :triaxle,
      :weight_decimal_humanized, :weight_is_metric,
      :vessel_name, :voyage_number,
      operations_attributes: [
        :id, :uid, :operation_type_id, :pos, :company_id, :yard_id, :trucker_id, :instructions
      ]
    ]
    params.require(:container).permit(attrs) rescue {}
  end

  def container_charges_params(type)
    type = "#{type}_container_charges".to_sym
    params.require(type).permit(
      params[type].keys.map do |id|
        { id => [:amount, :key, :delete_it, :uid, :auto_save, :chargable_type, :chargable_id, :company_id, :details, :operation_id] }
      end
    ) rescue {}
  end
end
