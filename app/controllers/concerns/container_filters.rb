module ContainerFilters
  extend ActiveSupport::Concern

  def deal_with_appt_time
    params[:container]||= {}
    c = params[:container]
    c["appt_start(1i)"] = c["appt_end(1i)"] = "2000" #very important by using 2000, if no, the changed attributes will include this appt_start/end
    c["appt_start(2i)"] = c["appt_end(2i)"] = "1"
    c["appt_start(3i)"] = c["appt_end(3i)"] = "1"
    if c["appt_start(4i)"].blank? || c["appt_start(5i)"].blank?
      5.times{|i| c.delete("appt_start(#{i+1}i)")}
      c[:appt_start] = nil
    end
    if c["appt_end(4i)"].blank? || c["appt_end(5i)"].blank?
      5.times{|i| c.delete("appt_end(#{i+1}i)")}
      c[:appt_end] = nil
    end
  end
end