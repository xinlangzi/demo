class NotificationsObserver < ActiveRecord::Observer
  attr_accessor :record
  observe :container, :operation, :image, :applicant, :alter_request, :day_log
  #### CATEGORIES ################
  # pending_j1s: 0,
  # alter_request: 1,
  # new_expiration_doc: 2,
  # new_driver_application: 3,
  # confirmed_without_appt_date: 4,
  # drops_awaiting_pick_up: 5
  ################################

  def after_create(record)
    @record = record
    case record
    when Container
      handle_confirmed_without_appt_date
    when Image
      handle_pending_j1s
      handle_expiration_doc
    when Applicant
      handle_applicant
    when AlterRequest
      handle_alter_request(:create)
    when DayLog
      handle_day_log(:create)
    else
    end
  end

  def after_update(record)
    @record = record
    case record
    when Container
      handle_confirmed_without_appt_date
    when Operation
      handle_drops_awaiting_pick_up
    when Image
      handle_pending_j1s
      handle_expiration_doc
    when AlterRequest
      handle_alter_request(:update)
    when DayLog
      handle_day_log(:update)
    end
  end

  def after_destroy(record)
    @record = record
    case record
    when Image
      handle_pending_j1s
    when AlterRequest
      handle_alter_request(:destroy)
    when DayLog
      handle_day_log(:destroy)
    else
    end
  end

  private

    def handle_confirmed_without_appt_date
      return unless @record.changed.map(&:to_sym).include?(:appt_date)
      cids = Container.confirmed.without_appt_date.pluck(:id)
      notification = Notification.confirmed_without_appt_date.first
      return notification.try(:destroy!) if cids.empty?
      attrs = { detail: "Containers: #{cids.join(', ')}" }
      if notification
        notification.update(attrs)
      else
        Notification.create(attrs.merge(category: :confirmed_without_appt_date))
      end
    end

    def handle_drops_awaiting_pick_up
      return unless @record.changed.map(&:to_sym).include?(:operated_at)
      cids = Container.drops_awaiting_pick_up.pluck(:id)
      notification = Notification.drops_awaiting_pick_up.first
      return notification.try(:destroy!) if cids.empty?
      attrs = { detail: "Containers: #{cids.join(', ')}" }
      if notification
        notification.update(attrs)
      else
        Notification.create(attrs.merge(category: :drops_awaiting_pick_up))
      end
    end

    def handle_pending_j1s
      return if @record.temp?
      count = Image.pending_j1s.count
      notification = Notification.pending_j1s.first
      return notification.try(:destroy!) if count == 0
      attrs = { detail: "There #{'is'.pluralize(count)} #{count} J1s pending to review." }
      if notification
        notification.update(attrs)
      else
        Notification.create(attrs.merge(category: :pending_j1s))
      end
    end

    def handle_expiration_doc
      return if @record.temp?
      if Trucker::EXPIRATION_COLUMNS.keys.include?(@record.column_name.try(:to_sym))
        if @record.pending?
          Notification.create(
            category: :new_expiration_doc,
            notifiable: @record,
            detail: "#{@record.user} uploaded a new expiration doc."
          )
        else
          Notification.new_expiration_doc.where(notifiable: @record).destroy_all
        end
      end
    end

    def handle_applicant
      Notification.create(
        category: :new_driver_application,
        detail: "#{@record.name} just applied online application."
      )
    end

    def handle_alter_request(action)
      case action
      when :destroy
        @record.notifications.destroy_all
      else
        Notification.create(
          category: :alter_request,
          notifiable: @record,
          detail: "#{@record.user} requested to change #{@record.attr.titleize} on #{@record.alter_requestable.to_s}."
        ) if @record.user
      end
    end

    def handle_day_log(action)
      case action
      when :create
        Notification.create(
          category: :daily_log,
          notifiable: @record,
          detail: "#{@record.user} uploaded a daily log for #{@record.issue_date}."
        ) unless @record.user.is_admin?
      else
        @record.notifications.destroy_all
      end
    end

end
