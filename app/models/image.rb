class Image < ApplicationRecord
  extend FriendlyId
  friendly_id :uuid, use: [:finders]
  acts_as_taggable
  mount_uploader :file, ImageUploader

  belongs_to :user
  belongs_to :imagable, polymorphic: true, touch: true

  validates :user_id, presence: true
  validates :file, presence: true

  enum status: { pending: 0, approved: 1, rejected: 2 }

  scope :pod, ->{ where(pod: true) }
  scope :non_approved, ->{ where.not(status: 1) }
  scope :j1s, ->{
    where(
      "imagable_type = ? OR column_name IN (?)",
      'Operation', ['chassis_pickup', 'chassis_return']
    )
  }
  scope :pending_j1s, ->{
    where(
      "(imagable_type = ? AND status = 0) OR (column_name IN (?) AND status = 0)",
      'Operation', ['chassis_pickup', 'chassis_return']
    )
  }
  scope :by_user, ->(user){ where(user_id: user.id) }
  scope :for_column, ->(name){ where(column_name: name.to_s) }
  scope :temp, ->{ where(imagable_type: nil) }

  before_create :init_status
  before_save :set_uuid
  after_create :summary_j1s
  after_destroy :summary_j1s

  def file_exists?
    file.file.try(:exists?)
  end

  def thumb_exists?
    file.thumb.file.try(:exists?)
  end

  def pdf_exists?
    file.pdf? ? file_exists? : file.pdf.file.try(:exists?)
  end

  def recreate_versions!
    file.recreate_versions! if file_exists?
  end

  def self.build(params)
    Image.transaction do
      image = Image.new(params)
      image.remove_pending_versions!
      yield image if block_given?
      image.save!
      image
    end
  end

  def remove_pending_versions!
    imagable.images.where(column_name: column_name).pending.destroy_all rescue nil
  end

  def approve!
    update!(status: :approved, comment: nil)
  end

  def reject!(comment)
    update!(status: :rejected, comment: comment)
  end

  def owner?(user)
    user_id == user.try(:id)
  end

  def can_write?(user)
    case user.class.to_s
    when 'Admin', 'SuperAdmin'
      true
    else
      owner?(user)&&!approved?
    end
  end

  def self.delete_by!(id, user)
    image = Image.find_by(uuid: id)
    raise "You can't access to this image." unless image
    if image.can_write?(user)
      raise "Failed to delete this image." unless image.destroy
    else
      raise "You can't delete this image."
    end
    image
  end

  def operation_time
    case imagable_type
    when /Operation/
      return imagable.view_operated_at
    when /Container/
      return imagable.chassis_pickup_at.try(:ymd) if column_name =~/chassis_pickup/
      return imagable.chassis_return_at.try(:ymd) if column_name =~/chassis_return/
    else
      nil
    end
  end

  def self.j1s_uploaded_by(user, options={})
    case true
    when options[:date].present?
      Image.by_user(user).j1s.where("DATE(created_at) = ?", options[:date].strip)
    when options[:container].present?
      id = options[:container].strip
      ids = Image.by_user(user)
             .joins("INNER JOIN operations ON operations.id = images.imagable_id AND images.imagable_type = 'Operation'")
             .joins("INNER JOIN containers ON containers.id = operations.container_id")
             .where("containers.id = ? OR containers.container_no = ?", id, id).pluck(:id)
      ids+= Image.by_user(user)
             .joins("INNER JOIN containers ON containers.id = images.imagable_id AND images.imagable_type = 'Container'")
             .where("containers.id = ? OR containers.container_no = ?", id, id).pluck(:id)
      Image.where(id: ids)
    else
      Image.none
    end
  end

  def to_h
    {
      id: id,
      url: file.url,
      filename: filename
    }
  end

  def to_s
    [imagable_type, imagable_id, column_name].join('-')
  end

  def filename
    read_attribute(:file)
  end

  def url
    file.url
  end

  def temp?
    imagable.nil?
  end

  def self.clear_temp
    Image.temp.delete_all
  end

  def non_auditable?
    %w{Maintenance}.include?(imagable_type)
  end

  def auditable?
    !non_auditable? && file_exists?
  end

  private
    def set_uuid
      self.uuid = SecureRandom.hex(6) if self.uuid.nil?
    end

    def init_status
      self.status||= :pending
    end

    def summary_j1s
      if Rails.env.test?
        RailsCache.rebuild_j1s
      else
        RailsCache.delay.rebuild_j1s
      end
    end

end
