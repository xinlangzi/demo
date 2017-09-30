require 'docusign_rest'
class Docusign::Base

  APPLICANT = 'Applicant'
  ADMIN = 'Admin'

  def initialize(options={})
    setting = SystemSetting.default
    DocusignRest.configure do |config|
      config.username       = setting.ds_username
      config.password       = setting.ds_password
      config.integrator_key = setting.ds_integrator_key
      config.account_id     = setting.ds_account_id
      config.endpoint       = setting.ds_endpoint
      config.api_version    = setting.ds_api_version
    end
    @subject     = options[:subject]
    @signers     = options[:signers] || []
    @template_id = options[:template_id]
    @return_url  = options[:return_url]
  end

  def client
    @client||= DocusignRest::Client.new
  end

  def recipient(role)
    @recipient||= @signers.detect{|signer| signer.role == role }
  end

  def create_envelope
    hash = {
      status:        "sent",
      emailSubject:  @subject,
      templateId:    @template_id,
      templateRoles: []
    }
    envelope_id = client.post("envelopes", hash)["envelopeId"]
    update_envelope_recipients(envelope_id)
    envelope_id
  end

  def get_envelope_recipients(envelope_id)
    client.get("envelopes/#{envelope_id}/recipients")
  end

  def update_envelope_recipients(envelope_id)
    recipients_signers = get_envelope_recipients(envelope_id)["signers"]
    array_signers = @signers.map do |signer|
      recipient_id = recipients_signers.detect{|rs| rs["roleName"] == signer.role }["recipientId"] rescue nil
      {
        clientUserId: signer.email,
        name: signer.name,
        email: signer.email,
        recipientId: recipient_id,
        roleName: signer.role
      }
    end
    hash = { signers: array_signers }
    client.put("envelopes/#{envelope_id}/recipients", hash)
  end

  def render_recipient_view(envelope_id, role: APPLICANT)
    hash = {
      authenticationMethod: "email",
      clientUserId:         recipient(role).email,
      email:                recipient(role).email,
      returnUrl:            @return_url,
      userName:             recipient(role).name
    }
    client.post("envelopes/#{envelope_id}/views/recipient", hash)
  end

  def status_completed?(envelope_id)
    get_envelope_recipients(envelope_id).signers.all?{|signer| signer.status.to_sym == :completed } rescue false
  end

  def self.combined_envelope_streem(envelope_id)
    Docusign::Base.new.client.get("envelopes/#{envelope_id}/documents/combined", { return_stream: true })
  end

end
