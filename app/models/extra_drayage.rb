class ExtraDrayage < ApplicationRecord
  belongs_to :container_size
  belongs_to :container_type
  belongs_to :ssline
  belongs_to :rail_road

  validates :container_size, :container_type, :ssline, :rail_road, presence: true

  def self.build(options={})
    styles = options.delete(:styles)
    ExtraDrayage.where(options).destroy_all
    Array(styles).remove_empty.each do |style|
      size, type = style.split(":")
      options.merge!(container_size_id: size, container_type_id: type)
      ExtraDrayage.create(options)
    end
  end

  def self.styles_by_ssline_and_rail_road
    ExtraDrayage.all.group_by(&:ssline_rail_road_ids).inject({}){|hash, (k, v)| hash[k] = v.map(&:style_ids); hash}
  end

  def ssline_rail_road_ids
    "#{ssline_id}:#{rail_road_id}"
  end

  def style_ids
    "#{container_size_id}:#{container_type_id}"
  end
end
