module YardsHelper
  def detailed_column_list
    list = super
    list['Hours of Operation'] = lambda{|c| h c.ophours}
    list
  end
end