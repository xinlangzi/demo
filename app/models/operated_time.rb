class OperatedTime
  attr_accessor :only_date, :datetime

  def initialize(only_date, datetime)
    @only_date = only_date
    @datetime = datetime
  end

  def >(object)
    return false if object.datetime.nil?
    if only_date
      datetime.to_date > object.datetime.to_date
    else
      datetime > (object.only_date ? object.datetime.end_of_day : object.datetime)
    end
  end

  def to_s
    if only_date
      datetime.to_date
    else
      datetime
    end
  end

end
