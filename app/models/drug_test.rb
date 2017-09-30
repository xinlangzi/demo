class DrugTest < ApplicationRecord
  belongs_to :trucker
  validates_presence_of :test_type, :date

  TYPES = ["Pre Employment", "Random"]

  validate do
    if (passed != nil) && date && date > Date.today
      errors.add :date, ": test is an upcoming event; results are not known yet"
    end
  end

  def passed=(value)
    if value == 'passed'
      write_attribute("passed", true)
    elsif value == 'failed'
      write_attribute("passed", false)
    else
      write_attribute("passed", nil)
    end
  end

end
