class DocusignsController < ApplicationController

  skip_before_action :check_authentication, :check_authorization

  def psp_returned
    utility = DocusignRest::Utility.new

    case params[:event]
    when /signing_complete/
      # render text: utility.breakout_path(wizard_applicants_path(commit: 'complete')), content_type: 'text/html'
      render html: utility.breakout_path(wizard_applicants_path(commit: 'complete')).html_safe
    when /ttl_expired/
      flash[:notice] = "Oops! The docusign request is timeout."
      # render text: utility.breakout_path(wizard_applicants_path), content_type: 'text/html'
      render html: utility.breakout_path(wizard_applicants_path).html_safe
    else
      flash[:notice] = "You chose not to sign the document."
      # render text: utility.breakout_path(wizard_applicants_path), content_type: 'text/html'
      render html: utility.breakout_path(wizard_applicants_path).html_safe
    end
  end

  def sign_returned
    utility = DocusignRest::Utility.new

    case params[:event]
    when /signing_complete/
      render html: utility.breakout_path(invitation_applicants_path(commit: 'complete')).html_safe
    when /ttl_expired/
      flash[:notice] = "Oops! The docusign request is timeout."
      render html: utility.breakout_path(invitation_applicants_path).html_safe
    else
      flash[:notice] = "You chose not to sign the document."
      render html: utility.breakout_path(invitation_applicants_path).html_safe
    end
  end
end
