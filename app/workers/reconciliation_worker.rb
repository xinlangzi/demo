class ReconciliationWorker < AbstractController::Base
  include AbstractController::Rendering
  include ActionView::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include AbstractController::Logger  # dependency from actionview calling logging
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker


  helper ApplicationHelper
  helper_method :cache

  def cache *args
    yield
  end

  append_view_path "#{Rails.root}/app/views"

  def perform(id)
    @reconciliation = Report::Reconciliation.find(id)
    @search = Payment.search
    @by_companies = @reconciliation.by_companies
    @classify_for_containers = @reconciliation.classify_by_container_charge
    @classify_for_third_parties = @reconciliation.classify_by_third_party_category
    @classify_for_adjustments = @reconciliation.classify_by_adjustment_category
    @classify_for_credits  = @reconciliation.classify_by_credit_category
    ActionView::Base.send(:define_method, :protect_against_forgery?) { false }
    html = render_to_string template: 'report/reconciliations/search'
    tempfile = Tempfile.new('Reconciliation')
    tempfile.write(html)
    @reconciliation.file = tempfile
    @reconciliation.save
    tempfile.close
  end
end
