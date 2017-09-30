require 'render_anywhere'
class Pod < ApplicationRecord
  include RenderAnywhere

  mount_uploader :signature, SignatureUploader
  belongs_to :container
  belongs_to :user

  validates :email, single_email: true
  validates :name, :signature, :user_id, :seal_no, :arrival_time, :departure_time, presence: true
  validates_datetime :departure_time, after: :arrival_time, after_message: 'must be after arrival time'

  validate :check_arrival_time

  def check_arrival_time
    delivery_operation.check_datetime(delivery_datetime) do |error|
      return errors.add(:base, error) if error
    end if delivery_operation && arrival_time
  end

  attr_accessor :signature_data

  after_create :set_delivery_datetime
  after_create :delay_save_pdf

  def self.init(container)
    container.pods.first_or_initialize(seal_no: container.seal_no)
    # Pod.new.tap do |pod|
    #   pod.container = container
    #   pod.seal_no = container.seal_no
    #   if pre = container.pods.last
    #     pod.name = pre.name
    #     pod.email = pre.email
    #     pod.seal_no = pre.seal_no
    #     pod.arrival_time = pre.arrival_time.strftime("%I:%M %p")
    #     pod.departure_time = pre.departure_time.strftime("%I:%M %p")
    #     pod.intact = pre.intact
    #     pod.measure = pre.measure
    #     pod.exceptions = pre.exceptions
    #   end
    # end
  end

  def delivery_operation
    @operation||= container.operations.delivery_mark.first
  end

  def delivery_datetime
    current = created_at || Date.current
    arrival_time.change(year: current.year, month: current.month, day: current.day)
  end

  def signature_data=(data)
    @signature_data = data
    if data.present?
      image_data = Base64.decode64(data['data:image/png;base64,'.length..-1])
      file = Tempfile.new("image-data")
      file.binmode
      file << image_data
      file.rewind
      img_params = { filename: 'signature.png', type: 'image/png', tempfile: file }
      self.signature = ActionDispatch::Http::UploadedFile.new(img_params)
    end
  end

  def save_pdf
    set_instance_variable(:pod, self)
    set_instance_variable(:owner, Owner.first)
    html = render(template: 'pods/show.html.slim', layout: 'pod.html')
    file = Tempfile.new("signature")
    file.binmode
    file << Wisepdf::Writer.new.to_pdf(html)
    file.rewind
    file_params = { filename: 'signature.pdf', type: 'application/pdf', tempfile: file }
    operation = delivery_operation
    if operation
      pdf = operation.images.build
      pdf.pod = true
      pdf.name = "POD"
      pdf.user = user
      pdf.file = ActionDispatch::Http::UploadedFile.new(file_params)
      if pdf.save
        pdf.approve!
        OrderMailer.pod_to_customer(self, pdf).deliver_now if email.present?
      end
    end
  end

  def receiver
    delivery_operation.try(:company)
  end

  def similars
    Pod.joins(container: { operations: :operation_type }).
        where("operation_types.delivered = ?", true).
        where("operations.company_id = ?", receiver.try(:id)).
        where("LENGTH(email) > 0").
        order("pods.id DESC")
  end

  def image
    @image||= MiniMagick::Image.open(signature.url) rescue MiniMagick::Image.open(signature.path)
  end

  def image_size
    "#{image.width}x#{image.height}"
  end

  private
    def set_delivery_datetime
      if delivery_operation
        delivery_operation.update_attribute(:operated_at, delivery_datetime)
        delivery_operation.alter_request_at(:operated_at).try(:destroy)
      end
    end

    def delay_save_pdf
      PodWorker.perform_in(15.seconds, id)
    end

end
