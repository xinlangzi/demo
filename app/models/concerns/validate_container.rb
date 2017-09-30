module ValidateContainer
  extend ActiveSupport::Concern

  included do
    validate :stale_version, on: :update, if: :vid
  end

  CONTAINER_FIELDS = [
    :admin_comment, :appt_date, :appt_start, :appt_end, :appt_is_range,
    :chassis_no, :commodity, :customer_comment,
    :chassis_pickup_company_id, :chassis_pickup_with_container, :chassis_return_with_container, :chassis_return_company_id,
    :container_no, :container_size_id, :container_type_id, :customer_id, :customers_employee_id,
    :early_receiving_date, :empty_release_no,
    :haz_cargo, :house_bl_no, :house_booking_no, :per_diem_lfd, :pickup_no, :public_comment,
    :rail_cutoff_date, :rail_lfd, :reference_no,
    :seal_no, :ssline_bl_no, :ssline_booking_no, :ssline_id, :terminal_eta, :to_save, :triaxle,
    :weight_decimal_humanized, :weight_is_metric,
    :vessel_name, :voyage_number
  ].freeze

  CONTAINER_CHARGE_FIELDS = [
    :amount, :chargable_id, :company_id, :details
  ].freeze

  OPERATION_FIELDS = [
    :appt, :instructions, :operation_type_id, :trucker_id, :yard_id
  ].freeze

  def stale_version
    if version = PaperTrail::Version.for_item(self).where(id: vid).first
      vs = PaperTrail::Version.for_item(self).where("id > ?", vid)

      updated_keys = vs.where(item_type: 'Container').map(&:dataset).map(&:keys).flatten.uniq.map(&:to_sym)
      errors.add(:vid, "Container is out of date.") if (updated_keys & CONTAINER_FIELDS).present?

      updated_keys = vs.where(item_type: 'ContainerCharge', event: 'update').map(&:dataset).map(&:keys).flatten.uniq.map(&:to_sym)
      errors.add(:vid, "Charge is out of date.") if (updated_keys & CONTAINER_CHARGE_FIELDS).present?

      updated_keys = vs.where(item_type: 'Operation', event: 'update').map(&:dataset).map(&:keys).flatten.uniq.map(&:to_sym)
      errors.add(:vid, "Operation is out of date.") if (updated_keys & OPERATION_FIELDS).present?

      created_or_deleted_associations = vs.where(item_type: ['Operation', 'ContainerCharge'], event: ['destroy', 'create'])
      errors.add(:vid, "Charge or operation is created or deleted.") if created_or_deleted_associations.present?
    end
  end
end
