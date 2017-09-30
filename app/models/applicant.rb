class Applicant < ApplicationRecord

  CDL_TAG = 'cdl'
  PSP_TAG = 'psp'
  attr_accessor :cdl_ids

  nospace :first_name, :last_name
  titleize :first_name, :last_name

  belongs_to :hub
  belongs_to :company
  belongs_to :cdl_state, class_name: 'State', foreign_key: :cdl_state_id
  has_many :images, as: :imagable, dependent: :destroy

  with_options on: [:create, :basic] do |a|
    a.validates :hub_id, presence: true
    a.validates :first_name, presence: true
    a.validates :last_name, presence: true
    a.validates :email, presence: true, uniqueness: { case_sensitive: false }
    a.validates :phone, presence: true, format: { with: /\A\(?\d{3}[) ]?\s?\d{3}[- ]?\d{4}\Z/i, multiline: true, message: "Must be like (123) 456-7890 or 123 456 7890." }
  end

  with_options on: [:create, :cdl] do |a|
    a.validates :date_of_birth, presence: true
    a.validates :year_of_experience, presence: true, numericality: { greater_than: 0, only_integer: true }
    a.validates :cdl_no, presence: true
    a.validates :cdl_state_id, presence: true
  end

  validate on: [:create, :cdl] do
    errors.add(:cdl, 'Please upload CDL') if cdl_docs.empty?
  end

  after_create :build_token
  after_create :link_cdls
  after_create :save_signed_psp
  after_create :notify_hr

  alias_attribute :trucker, :company

  scope :in_hub, ->(user){
    where(hub: Hub.with_default.for_user(user))
  }

  scope :only_deleted, ->{
    unscoped.where.not(deleted_at: nil)
  }

  default_scope { where(deleted_at: nil) }

  def name
    "#{first_name.strip} #{last_name.strip}"
  end

  def identifier
    "#{name}#{email}".gsub(/\W/, '').downcase
  end

  def cdl_docs
    Image.where(id: cdl_ids)
  end

  def self.query(options={})
    attrs = { email: options[:email], cdl_no: options[:cdl_no] }
    Applicant.unscoped.where(attrs).first_or_initialize
  end

  def invite
    unless hired?
      build_trucker
      build_token
      move_docs
      update(invited_at: Date.today)
      ApplicantMailer.delay.invite(id)
    end
  end

  def hire_now
    remove_token
    trucker.hire_now
    trucker.notify_password_initialization
    trucker.notify_mobile_apps
  end

  def hired?
    trucker.try(:hire_date).present?
  end

  def deleted?
    deleted_at.present?
  end

  def delete!
    if deleted?
      destroy!
    else #soft deleted
      trucker = self.company
      update(token: nil, company_id: nil, deleted_at: Time.now)
      trucker.try(:destroy)
    end
  end

  def init_docusign
    ss = SystemSetting.default
    Docusign::Base.new(
      subject: 'PSP Disclosure & Authorization',
      signers: [
        {
          name: name,
          email: email,
          role: 'Applicant',
          recipient: true
        }
      ],
      template_id: ss.ds_psp_template_id,
      return_url: Rails.application.routes.url_helpers.psp_returned_docusigns_url
    )
  end


  private
    def build_trucker
      unless company
        trucker = hub.truckers.build(
          name: name, email: email, phone_mobile: phone,
          date_of_birth: date_of_birth, dl_no: cdl_no, dl_state_id: cdl_state_id,
          driver_type: :contract_driver, mark: :uncertain
        )
        trucker.save(validate: false)
        trucker.create_docusign
        update(company: trucker)
      end
      unless Truck.default(company)
        trucker.trucks.build.save(validate: false)
      end
    end

    def build_token
      update_column(:token, SecureRandom.hex(16)) unless invited_at
    end

    def remove_token
      update_column(:token, nil)
    end

    def link_cdls
      Image.where(id: cdl_ids).each do |image|
        image.imagable = self
        image.column_name = CDL_TAG
        image.save(validate: false)
      end
    end

    def move_docs
      images.each do |image|
        unless image.file_exists?
          image.delete
        else
          image.imagable = company
          image.user = company
          case image.column_name
          when CDL_TAG
            image.column_name = Trucker::DLE_TAG
            image.save!
          when PSP_TAG
            image.column_name = Trucker::PSP_TAG
            image.save!
          end
        end
      end
    end

    def notify_hr
      ApplicantMailer.delay_for(1.minute).notify_hr(id)
    end

    def save_signed_psp
      if envelope_id
        stream_data = Docusign::Base.combined_envelope_streem(envelope_id)
        file = Tempfile.new("pdf-data")
        file.binmode
        file << stream_data
        file.rewind
        img_params = { filename: 'psp-signed.pdf', type: 'application/pdf', tempfile: file }
        image = images.build(column_name: PSP_TAG, status: :approved)
        # image = images.build(column_name: PSP_TAG, imagable: self, status: :approved)
        image.file = ActionDispatch::Http::UploadedFile.new(img_params)
        image.save(validate: false)
      end
    end

    CUSTOMIZED_FIELDS = {
      bank_info: {
        bank_name: { required: true }, bank_account: { required: true }, digit_routing_number: { required: true }, account_type: { type: :radio_buttons, options: [:checking, :savings], required: true }, bank_account_beneficiary: { required: true }
      },
      emergency_contact_person: {
        name: { required: true }, relationship: { required: true }, phone: { required: true }
      },
      education: {
        high_school: {}, college: {}, other: { type: :text }
      },
      accident1: {
        date: { type: :datepicker }, location: {}, num_of_injuries: {}, num_of_fatalities: {}, hazmat_spill: {}
      },
      accident2: {
        date: { type: :datepicker }, location: {}, num_of_injuries: {}, num_of_fatalities: {}, hazmat_spill: {}
      },
      accident3: {
        date: { type: :datepicker }, location: {}, num_of_injuries: {}, num_of_fatalities: {}, hazmat_spill: {}
      },
      accident4: {
        date: { type: :datepicker }, location: {}, num_of_injuries: {}, num_of_fatalities: {}, hazmat_spill: {}
      },
      employer1: {
        name: {}, address: {}, city: {}, state: {}, zip_code: {}, contact_person: {}, phone: {}, did_you_drive_a_vehicle_requiring_a_cdl: { type: :boolean }, from: { type: :datepicker }, to: { type: :datepicker }, position_held: {}, salary_wage: {}, reason_for_leaving: { type: :text }
      },
      employer2: {
        name: {}, address: {}, city: {}, state: {}, zip_code: {}, contact_person: {}, phone: {}, did_you_drive_a_vehicle_requiring_a_cdl: { type: :boolean }, from: { type: :datepicker }, to: { type: :datepicker }, position_held: {}, salary_wage: {}, reason_for_leaving: { type: :text }
      },
      employer3: {
        name: {}, address: {}, city: {}, state: {}, zip_code: {}, contact_person: {}, phone: {}, did_you_drive_a_vehicle_requiring_a_cdl: { type: :boolean }, from: { type: :datepicker }, to: { type: :datepicker }, position_held: {}, salary_wage: {}, reason_for_leaving: { type: :text }
      },
      employer4: {
        name: {}, address: {}, city: {}, state: {}, zip_code: {}, contact_person: {}, phone: {}, did_you_drive_a_vehicle_requiring_a_cdl: { type: :boolean }, from: { type: :datepicker }, to: { type: :datepicker }, position_held: {}, salary_wage: {}, reason_for_leaving: { type: :text }
      },
      license: {
        have_your_license_ever_been_suspended_or_revoked: { type: :radio_buttons, options: [:yes, :no] }, detail: { type: :text }
      },
      straight_truck: {
        from: { type: :datepicker }, to: { type: :datepicker }, approx_num_of_miles: { }
      },
      semi_trailer: {
        from: { type: :datepicker }, to: { type: :datepicker }, approx_num_of_miles: { }
      }
    }

    CUSTOMIZED_FIELDS_GROUPS = {
      bank_information: [:bank_info],
      emergency_contact_person: [:emergency_contact_person],
      education: [:education],
      accidents: [:accident1, :accident2, :accident3, :accident4],
      employers: [:employer1, :employer2, :employer3, :employer4],
      license: [:license],
      driver_expirences: [:semi_trailer, :straight_truck]
    }

end
