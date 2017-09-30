module SuperAdminsHelper
  def detailed_column_list
    list = super
    list.delete('Accessible Hubs')
    list
  end
end