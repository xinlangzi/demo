class FinePrint
  def self.unsure_of_ssl_chassis
    SystemSetting.default.unsure_of_ssl_chassis_fine_print.gsub('$SSLINES', "#{Ssline.has_chassis_fee.map(&:name).to_sentence}") rescue nil
  end

  def self.two_day_accrual_drop
    SystemSetting.default.two_day_accrual_drop_fine_print
  end

  def self.three_day_accrual_drop
    SystemSetting.default.three_day_accrual_drop_fine_print
  end

  def self.additional_drayage(ssline, rail_road)
    SystemSetting.default.additional_drayage.gsub('$SSL', ssline.name).gsub('$RR', rail_road.name) rescue nil
  end

  def self.default
    SystemSetting.default.default_fine_print
  end
end