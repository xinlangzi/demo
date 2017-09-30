module TrucksHelper

  def detailed_column_list
    list = {}
    list['Default']                = ->(c){ checkmark(c.default) }
    list['No.']                 = ->(c){ h c.number }
    list['Year']                   = ->(c){ h c.year }
    list['Make']                   = ->(c){ h c.make }
    list['Model']                  = ->(c){ h c.model }
    list['VIN']                    = ->(c){ h c.vin }
    list['GVWR']                   = ->(c){ h c.gvwr }
    list['Tire Size']              = ->(c){ h c.tire_size }
    list['Registered States']      = ->(c){ h c.states.map(&:abbrev).join(', ')}
    list['License Plate No.']      = ->(c){ h c.license_plate_no }
    list['License Plate Expires']  = ->(c){
      display_date_with_status(c.license_plate_expiration) +
      attachments_for(c, :license_plate_expiration)
    }
    list['Annual Inspection Expires']  = ->(c){
      display_date_with_status(c.tai_expiration) +
      attachments_for(c, :annual_inspection_expiration)
    }
    list['Bobtail Insurance Expires']  = ->(c){
      display_date_with_status(c.bobtail_insurance_expiration) +
      attachments_for(c, :bobtail_insurance_expiration)
    }
    list['IFTA Expires']  = ->(c){
      display_date_with_status(c.ifta_expiration, applicable: c.ifta_applicable) +
      attachments_for(c, :ifta_expiration)
    }
    list['Last Quarterly Maint. Report']  = ->(c){
      display_date_with_status(c.last_quarterly_maintenance_report, date_show: c[:last_quarterly_maintenance_report]) +
      attachments_for(c, :last_quarterly_maintenance_report)
    }
    list
  end

end
