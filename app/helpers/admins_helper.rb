module AdminsHelper
  def detailed_column_list
    list = super
    list['Accessible Hubs'] =->(c){ c.hubs.map(&:name).join(", ") }
    list
  end
end