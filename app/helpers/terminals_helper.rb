module TerminalsHelper
  def column_list
    {
      'Name' => ->(c){ link_to(c.name, c).html_safe},
      'State' => ->(c){ h c.state },
      'Containers' => ->(c){ h c.containers.count("DISTINCT containers.id")},
      'Rail Fee' => lambda { |company|
        return company.rail_fee unless current_user.is_superadmin?
        fields_for :company, company do |c|
          c.text_field :rail_fee, class: "w80 center auto-save nospace", id: "rail_fee_#{company.id}", ref: "#{company.class.to_s}:#{company.id}:rail_fee"
        end
      },
      'Rail Road' => lambda{|company|
        return company.rail_road.try(:name) unless current_user.is_superadmin?
        fields_for :company, company do |c|
          c.grouped_collection_select :rail_road_id, Port.all, :rail_roads, :name, :id, :name, { include_blank: true }, { class: "auto-save", id: "rail_road_id_#{company.id}", ref: "#{company.class.to_s}:#{company.id}:rail_road_id" }
        end
      }
    }
  end

  def detailed_column_list
    list = super
    list.insert(1, "Print Name", ->(c){ h c.print_name })
    list["Rail Fee"]  = ->(c){ h c.rail_fee }
    list["Rail Road"]  = ->(c){ h c.rail_road.name rescue nil}
    list['Hours of Operation'] = ->(c){ h c.ophours }
    list
  end
end
