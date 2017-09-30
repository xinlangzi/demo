class Datepicker
  attr_accessor :object, :method, :id, :date
  def self.set_date(params)
    params[:klass].constantize.unscoped.find(params[:id]).tap do |object|
      object.partial_save(params[:method] => params[:date])
    end
  end

  def self.reset_date(params)
    params[:klass].constantize.unscoped.find(params[:id]).tap do |object|
      object.partial_save(params[:method] => nil)
    end
  end
end
