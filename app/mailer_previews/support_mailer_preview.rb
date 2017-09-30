class SupportMailerPreview < ActionMailer::Preview

  def send_message
    SupportMailer.send_message("Daniel", message)
  end

  private
  def message
    <<-EOT.gsub(/^\s+/, '')
      Some
      Very
      Interesting
      Stuff
    EOT
  end
end
