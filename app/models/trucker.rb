require 'csv'
class Trucker < User
  serialize :tasks, JSON

  titleize :name

  attr_accessor :check_trucks

  PSP_TAG        = 'psp'
  MVR_TAG        = 'mvr'
  OTHER_TAG      = 'other'
  DOCUSIGN_TAG   = 'docusign'
  DLE_TAG        = 'driver_license_expiration'
  VOID_CHECK_TAG = 'void_check'

  include HubAssociation
  belongs_to_hub presence: true

  has_many :operations
  has_many :containers, ->{ order('containers.appt_date ASC').distinct }, through: :operations
  has_many :trucks, dependent: :destroy
  has_many :daily_mileages, :through => :trucks
  has_many :fuel_purchases, dependent: :destroy
  has_many :drug_tests, ->{ order('date DESC') }, dependent: :destroy
  has_many :operations, dependent: :nullify
  has_many :images, as: :imagable, dependent: :destroy
  has_many :inspections, dependent: :nullify
  has_many :maintenances, dependent: :nullify
  has_many :cancelled_appointments, dependent: :destroy
  has_many :day_logs, dependent: :destroy
  has_one  :applicant, class_name: 'Applicant', foreign_key: :company_id
  belongs_to :dl_state, class_name: 'State', foreign_key: :dl_state_id

  accepts_nested_attributes_for :trucks,  allow_destroy: true

  enum mark: { uncertain: 0 }
  enum driver_type: { owner_operator: 1, contract_driver: 0 }

  validates :name, :phone_mobile, presence: true
  validates :address_street, :address_city, :address_state_id, :zip_code, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :ssn, format: { with: /\A\d{3}-?\d{2}-?\d{4}\Z/, message: "must be in the following format: xxx-xx-xxxx" }, allow_blank: true

  validates_associated :trucks, if: :check_trucks

  scope :haz_cargo_endorsement, ->{ where(dl_haz_endorsement: true) }
  scope :active, ->{ where(deleted_at: nil, termination_date: nil) }
  scope :hired, ->{ active.where.not(hire_date: nil) }
  scope :group_options, ->{ where(deleted_at: nil, termination_date: nil) }
  scope :valid_mobile_phone, ->{ where('companies.phone_mobile IS NOT NULL AND companies.phone_mobile <> ""') }
  scope :inactive, ->{ where('companies.termination_date IS NOT NULL') }

  DOC_NAME_MAPS = {
    avatar: 'Driver & Truck',
    hire_date: 'Hire Date',
    driver_license_expiration: 'Driver License',
    ownership: 'Truck Title or Proof of Ownership',
    medical_card_expiration: 'Medical Card',
    truck_no: 'Truck No.',
    annual_inspection_expiration: 'Annual Inspection',
    license_plate_expiration: 'License Plate',
    ifta_expiration: 'IFTA',
    bobtail_insurance_expiration: 'Bobtail Insurance',
    last_quarterly_maintenance_expiration: 'Last Quarterly Maint. Report'
  }.freeze

  EXPIRATION_COLUMNS = {
    hire_date: :hire_date,
    driver_license_expiration: :dl_expiration_date,
    medical_card_expiration: :medical_card_expiration_date,
    annual_inspection_expiration: :tai_expiration,
    license_plate_expiration: :license_plate_expiration,
    ifta_expiration: :ifta_expiration,
    bobtail_insurance_expiration: :bobtail_insurance_expiration,
    last_quarterly_maintenance_expiration: :last_quarterly_maintenance_report
  }.freeze

  TRUCKER_EXPIRATION_COLUMNS = EXPIRATION_COLUMNS.slice(
    :driver_license_expiration, :medical_card_expiration
  ).freeze

  TRUCK_EXPIRATION_COLUMNS = EXPIRATION_COLUMNS.slice(
    :annual_inspection_expiration, :license_plate_expiration, :ifta_expiration,
    :bobtail_insurance_expiration, :last_quarterly_maintenance_expiration
  ).freeze

  after_create :assign_trucker_role
  after_update :ready_to_check_missing_doc## to-remove
  after_update :reset_docusign_envelope_id
  after_update :sync_applicant

  default_scope { where(mark: nil).order("companies.name ASC") }

  def self.load_miles(hub, date)
    sql = Sqls::Template::TRUCKER_MILES_BY_DATE%([date, date, date, date, date, hub.id])
    Sqls::Template.run(sql).map{|result| DriverStatus.new(date, result)}
  end

  def active?
    self.termination_date.nil?&&self.deleted_at.nil?
  end

  def assign_trucker_role
    self.roles << Role.find_by(name: "Trucker")
  end

  def self.default_rights
     Role.find_by(name: 'Trucker').default_rights
  end

  # def pin
  #   read_attribute(:pin) || generate_pin!(6)
  # end

  # def generate_pin!(size)
  #   self.pin = ((p = rand(10**size)).to_s.size==size ) ? p : generate_pin!(size)
  # end

  def mark_as_deleted
    transaction {
      super
    }
  end

  def is_trucker?
    true
  end

  def get_tasks(type)
    tasks.send(type) rescue []
  end

  def update_tasks(type, values)
    self.tasks||= {}
    self.tasks[type] = values.blank? ? [] : values
    save(validate: false)
  end

  def tasks_done?(type)
    case type.try(:to_sym)
    when :hired
      (SystemSetting.tasks_for_hired_driver - get_tasks(:hired)).empty?
    when :terminated
      (SystemSetting.tasks_for_terminated_driver - get_tasks(:terminated)).empty?
    else
      false
    end
  end

  def employment_status
    return "inactive" if !deleted_at.nil? || !termination_date.nil?
    "active"
  end

  def self.work_stats(truckers, from, to)
    summary  = {}
    from = from.to_date || Date.new(2000, 1, 1)
    to   = to.to_date || Date.today
    truckers.each do |trucker|
      a = [trucker.hire_date, from].compact.max
      b = [trucker.termination_date, trucker.deleted_at.try(:to_date), to].compact.min
      weekdays = (a..b).reject{|d|  [6, 0].include?(d.wday)} #exclude Sat, Sun
      unless weekdays.empty?
        points = trucker.inspections.range(a, b).sum(:point)
        vacations = Vacation.range(a, b)
                            .where(user_id: trucker.id)
                            .where(weight_factor: 0)
                            .order("vstart ASC")
                            .pluck("DISTINCT(vstart)")
        dispatched = Operation.where("actual_appt BETWEEN ? AND ?", a, b)
                              .where("DAYOFWEEK(actual_appt) NOT IN (7, 1)") #exclude Sat, Sun
                              .where(trucker_id: trucker.id)
                              .order("actual_appt ASC")
                              .pluck("DISTINCT(actual_appt)")
        # puts "Weekdays: #{weekdays.size} Vacations: #{vacations.size} Dispatched: #{dispatched.size}"
        vacations = vacations - dispatched
        summary[trucker.id] = {
          points: points,
          weekdays: weekdays.size,
          vacations: vacations.size,
          dispatched: dispatched.size,
          undispatched: (weekdays - vacations - dispatched).size,
          worked_ratio: Rational(dispatched.size, weekdays.size).to_f.round(2)
        }
      end
    end
    summary
  end

  def self.to_work_stats_csv(work_stats)
    CSV.generate do |csv|
      csv << [
        'Driver',
        'Hire date',
        'Weekdays',
        'Dispatched Days',
        'Undispatched Days',
        'Vacation Days',
        'Days Worked'
      ]
      work_stats.each do |id, info|
        trucker = Trucker.find(id)
        csv << [
          trucker.name,
          trucker.hire_date,
          info[:weekdays].size,
          info[:dispatched].size,
          info[:undispatched].size,
          info[:vacations].size,
          "#{(info[:worked_ratio]*100).round(2)}%"
        ]
      end
    end
  end

  CSV_EXPORT_DATE_FORMAT="%m-%d-%Y"

  def self.to_csv(truckers)
    csv_data = CSV.generate do |csv|
        csv << ['Driver',
        'Hire Date',
        'Termination Date',
        'Employment Status',
        'Phone No.',
        'Email Address',
        'Date of Birth',
        'Driver License No.',
        'Driver License Expires On',
        'Medical Card Expires On',
        'Make',
        'Year',
        'VIN#',
        'Truck No.',
        'Annual Inspection Expires On',
        'Licence Plate Expires On',
        'IFTA Expires On',
        'Bobtail Insurance Expires On',
        'Last Quarterly M&N Report'
       ]

      truckers.each do |trucker|
        trucker.trucks.each do |t|
        csv << [trucker.name,
          (trucker.hire_date.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (trucker.termination_date.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          trucker.employment_status,
          trucker.phone,
          trucker.email,
          (trucker.date_of_birth.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          trucker.dl_no,
          (trucker.dl_expiration_date.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (trucker.medical_card_expiration_date.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          t.make,
          t.year,
          t.vin,
          t.number,
          (t.tai_expiration.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (t.license_plate_expiration.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (t.ifta_expiration.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (t.bobtail_insurance_expiration.strftime(CSV_EXPORT_DATE_FORMAT) rescue ""),
          (t[:last_quarterly_maintenance_report].strftime(CSV_EXPORT_DATE_FORMAT) rescue "")
       ]
        end
      end
    end
  end

  def self.send_smses(truckers, message)
    truckers.collect do |id|
      Trucker.find(id).send_sms(message)
    end
  end

  def send_sms(message)
    TextMessage.create(trucker_id: id, message: message, phone_number: phone_mobile, status: "Sent")
  end

  def has_pending_approval_renew_doc?(type)
    images.pending.for_column(type.to_s).exists?
  end

  def pure_mobile_phone
    self.phone_mobile ? "+1" + self.phone_mobile.gsub(/\D/, "") : nil
  end

  def has_expiration_date?
    dates = []
    dates << dl_expiration_date if hub.driver_license_expiration
    dates << medical_card_expiration_date if hub.medical_card_expiration
    trucks.each do |truck|
      dates << truck.tai_expiration if hub.annual_inspection_expiration
      dates << truck.license_plate_expiration if hub.license_plate_expiration
      dates << truck.ifta_expiration if hub.ifta_expiration && truck.ifta_applicable
      dates << truck.bobtail_insurance_expiration if hub.bobtail_insurance_expiration
      dates << truck[:last_quarterly_maintenance_report] if hub.last_quarterly_maintenance_expiration
    end
    dates.any? do |date|
      date.nil? || date < Date.today
    end
  end

  def hire_now
    update_columns(hire_date: Date.today, mark: nil) if hire_date.blank?
  end

  def notify_password_initialization
    request_init_password
    url = Rails.application.routes.url_helpers.set_password_url(code: reload.uuid)
    message = "%s: Click link to initialize password\n%s"%[Owner.first.name, url]
    send_sms(message)
  end

  def notify_mobile_apps
    MyMailer.delay.mobile_apps(id)
    message = "%s: Download/Install Moible App\nAndroid: %s\niPhone: %s"%[Owner.first.name, ANDROID_APP_URL, IOS_APP_URL]
    send_sms(message)
  end

  def init_docusign
    ss = SystemSetting.default
    if contract_driver?
      subject = 'Contract Driver Document'
      template_id = ss.ds_contract_driver_template_id
    else
      subject = 'Owner Operator Document'
      template_id = ss.ds_owner_operator_template_id
    end

    Docusign::Base.new(
      subject: subject,
      signers: [
        {
          name: name,
          email: email,
          role: Docusign::Base::APPLICANT
        },
        {
          name: ss.ds_admin_name,
          email: ss.ds_admin_email,
          role: Docusign::Base::ADMIN
        }
      ],
      template_id: template_id,
      return_url: Rails.application.routes.url_helpers.sign_returned_docusigns_url
    )
  end

  def create_docusign
    unless driver_docusign_envelope_id
      update_column(:driver_docusign_envelope_id, init_docusign.create_envelope)
    end
  end

  def embedded_docusign_url(role)
    ds = init_docusign
    if driver_docusign_envelope_id
      ds.update_envelope_recipients(driver_docusign_envelope_id)
    else
      create_docusign
    end
    ds.render_recipient_view(driver_docusign_envelope_id, role: role).url
  end

  def docusign_file
    images.where(column_name: DOCUSIGN_TAG).first
  end

  def self.save_docusign
    Trucker.unscoped.where.not(driver_docusign_envelope_id: nil).each do |trucker|
      next if trucker.images.where(column_name: DOCUSIGN_TAG).exists?
      ds = trucker.init_docusign
      completed = ds.status_completed?(trucker.driver_docusign_envelope_id)
      if completed
        stream_data = Docusign::Base.combined_envelope_streem(trucker.driver_docusign_envelope_id)
        file = Tempfile.new("pdf-data")
        file.binmode
        file << stream_data
        file.rewind
        img_params = { filename: 'driver-signed.pdf', type: 'application/pdf', tempfile: file }
        image = trucker.images.build(column_name: DOCUSIGN_TAG, status: :approved)
        image.file = ActionDispatch::Http::UploadedFile.new(img_params)
        image.save(validate: false)
      end
    end
  end

  private
    def ready_to_check_missing_doc ## to-remove
      if check_missing_doc_changed?&&check_missing_doc?
        Container.joins(:operations)
                .where("operations.trucker_id = ?", id)
                .where("containers.appt_date < ?", Date.today - 3.days)
                .update_all(waive_docs: true)
      end
    end

    def reset_docusign_envelope_id
      if driver_type_changed?
        update_column(:driver_docusign_envelope_id, nil)
      end
    end

    def sync_applicant
      applicant.update_column(:email, email) if email_changed? && applicant
    end
end
