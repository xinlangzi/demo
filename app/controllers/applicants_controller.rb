class ApplicantsController < ApplicationController
  skip_before_action :check_authentication, :check_authorization, only: [
    :new, :wizard, :invitation, :status, :completed, :edit, :update, :upload
  ]

  before_action :set_applicant, only: [:show, :destroy, :invite, :sign, :hire]
  before_action :init_session_cache, only: [:new, :wizard, :upload]
  after_action :cache_cdl_uploader, only: [:upload]

  WIZARD_STEPS = [:basic, :cdl, :psp, :completed].freeze
  INVITATION_STEPS = [:basic, :docs, :sign, :completed].freeze

  layout 'application'

  def new
    session[:step] = WIZARD_STEPS.first
    redirect_to wizard_applicants_path
  end

  def wizard
    session[:applicant].merge!(secure_params.to_h)
    @applicant = Applicant.new(session[:applicant])
    case params[:commit]
    when /next/i
      valid = @applicant.valid?(session[:step])
      go_to_next_step(WIZARD_STEPS) if valid
    when /previous/i
      go_to_prev_step(WIZARD_STEPS)
    when /complete/i
      go_to_next_step(WIZARD_STEPS)
    else
    end
    process_wizard_step
    render layout: 'visitor'
  end

  def invitation
    if session[:atoken]
      @applicant = Applicant.find_by(token: session[:atoken])
      raise ActiveRecord::RecordNotFound unless @applicant
      @trucker = @applicant.company
      case params[:commit]
      when /next/i
        if session[:step] == :basic
          applicant_params = params[:trucker][:applicant].permit! rescue {}
          @applicant.assign_attributes(applicant_params)
          @applicant.save(validate: false)
          @trucker.assign_attributes(trucker_params)
          @trucker.save(validate: false)
        end
        go_to_next_step(INVITATION_STEPS)
      when /previous/i
        go_to_prev_step(INVITATION_STEPS)
      when /complete/i
        go_to_next_step(INVITATION_STEPS)
      end
      process_invitation_step
      render layout: 'visitor'
    else
      redirect_to root_path
    end
  end

  def status
    @applicant = Applicant.query(secure_params)
    render layout: 'visitor'
  end

  def edit
    session[:step] = INVITATION_STEPS.first
    session[:atoken] = params[:id]
    redirect_to invitation_applicants_path
  end

  def index
    @applicants = Applicant.in_hub(current_user).order("id DESC").page(params[:page])
  end

  def deleted
    @applicants = Applicant.in_hub(current_user).only_deleted.page(params[:page])
  end

  def show
  end

  def destroy
    @applicant.delete!
    respond_to do |format|
      format.html { redirect_to applicants_url, notice: 'Applicant was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def upload
    @applicant = Applicant.find_by(token: params[:id])
    @image = Image.new(doc_params)
    @image.file = params[:file]
    @image.status = :pending
    @image.user = @applicant.try(:company)
    @image.save(validate: false)
    respond_to do |format|
      format.json
    end
  end

  def invite
    @applicant.invite
    redirect_to @applicant, notice: 'Invitation was sent to the applicant successfully!'
  end

  def sign
    @trucker = @applicant.company
    @embedded_docusign_url = @trucker.embedded_docusign_url(params[:role])
    render layout: 'visitor'
  end

  def hire
    @applicant.hire_now
    redirect_to @applicant, notice: 'Email/SMS was sent to the applicant to initialize password and download mobile app.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_applicant
      @applicant = Applicant.unscoped.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def secure_params
      params.require(:applicant).permit(
        :hub_id, :first_name, :last_name, :email, :phone, :comment,
        :cdl_no, :cdl_state_id, :date_of_birth, :year_of_experience
      ) rescue {}
    end

    def trucker_params
      params.require(:trucker).permit(
        :name, :email, :date_of_birth,
        :phone_mobile, :onfile1099, :driver_type, :print_name, :contact_person, :fein,
        :address_street, :address_street_2, :address_city, :address_state_id, :zip_code, :residence_years,
        :billing_street, :billing_street_2, :billing_city, :billing_state_id, :billing_zip_code,
        :ssn, :dl_no, :dl_state_id, :dl_haz_endorsement,
        trucks_attributes: [
          :id, :number, :license_plate_no,
          :vin, :gvwr, :tire_size, :make, :model, :year,
          state_ids: []
        ]
      )
    end

    def doc_params
      params.require(:image).permit(:column_name, :imagable_id, :imagable_type) rescue {}
    end

    def go_to_prev_step(steps)
      index = steps.index(session[:step]) - 1
      index = 0 if index < 0
      session[:step] = steps[index]
    end

    def go_to_next_step(steps)
      session[:step] = steps[steps.index(session[:step]) + 1] || steps.last
    end

    def process_wizard_step
      case session[:step]
      when /psp/
        ds = @applicant.init_docusign
        identifier = @applicant.identifier
        session[identifier]||= ds.create_envelope
        session[:applicant][:envelope_id] = session[identifier]
        response = ds.render_recipient_view(session[identifier])
        @embedded_docusign_url = response.url
        logger.info("Applicant Identifier: " + identifier)
        logger.info("Docusign Envelope: " + session[identifier])
        logger.info("Docusign URL: " + @embedded_docusign_url)
      when /complete/
        reset_session_cache if @applicant.save
      end
      logger.info("Applicant Session: " + session[:applicant].to_s)
    end

    def process_invitation_step
      case session[:step]
      when /sign/
        @trucker.check_trucks = true
        if @trucker.valid?
          if @trucker.driver_docusign_published?
            @embedded_docusign_url = @trucker.embedded_docusign_url(Docusign::Base::APPLICANT)
            logger.info("Docusign URL: " + @embedded_docusign_url)
          end
        else
          session[:step] = :basic
        end
      when /complete/
        reset_session_cache
      end
    end

    def cache_cdl_uploader
      if session[:step] =~/cdl/
        session[:applicant][:cdl_ids]||= []
        session[:applicant][:cdl_ids] << @image.id if @image.temp?
      end
    end

    def init_session_cache
      session[:step]||= WIZARD_STEPS.first
      session[:applicant]||= {}
    end

    def reset_session_cache
      session[:applicant] = nil
      session[:atoken] = nil
    end

end
