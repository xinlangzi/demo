require 'sidekiq/web'
Rails.application.routes.draw do

  mount ActionCable.server => '/cable'
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if defined?(LetterOpenerWeb)
  mount Sidekiq::Web, at: '/sidekiq', constraints: lambda{|request| AuthConstraint.superadmin?(request) }

  resources :searches do
    collection do
      get :invoices
      get :companies
    end
  end

  resources :alter_requests do
    member do
      put :approve
    end
  end
  resources :hubs do
    get :switch, on: :member
    patch :restore, on: :member
    resources :mile_rates, only: [:update]
    resources :customer_rates, only: [:new] do
      collection do
        put :save
      end
    end
    resources :driver_rates, only: [:new] do
      collection do
        put :save
      end
    end
    resources :driver_drop_rates, only: [:new] do
      collection do
        put :save
      end
    end

    resources :customer_drop_rates, only: [:new] do
      collection do
        put :save
      end
    end
  end

  resources :avail_stats do
    collection do
      get :refresh
      get :appt_range
      get :detail
    end
  end
  resources :vacations do
    member do
      get :adjust
    end
  end
  resources :holidays
  resources :datepickers
  resources :modes do
    collection do
      get :driver
    end
  end
  resources :attrs do
    member do
      get :dups
    end
  end
  resources :drivers do
    collection do
      get :search
      get :summary
      get :assign
      get :cancel
    end
    member do
      get :vacation
      get :locate
      get :info
    end
    resources :docs
  end
  resources :docs do
    collection do
      get :search
      put :assign
      get :list
      get :containers
    end
    member do
      get :review
      patch :approve
      patch :reject
    end
  end
  resources :operation_types do
    collection do
      get :options
      get :choose_company
    end
  end
  resources :operation_emails do
    member do
      get :preview
    end
  end
  resources :operations do
    member do
      post :operate
      post :appt
      delete :cancel_operate
      get :reload
      get :link
      get :link_me
      get :unlink
      get :notify
    end
    collection do
      get :linkable
    end
  end
  resources :sql, only: [:show]
  resources :rail_bills do
    collection do
      patch :build
    end
  end
  resources :equipment_releases do
    collection do
      patch :build
    end
  end
  resources :link_codes
  resources :headers do
    member do
      get :toggle
    end
  end

  namespace "edi" do
    resources :logs do
      collection do
        get :incomplete
      end
    end
  end

  namespace 'accounting' do
    resources :invoices do
      collection do
        get :filter
      end
    end
    resources :payable_invoices do
      collection do
        put :update_total
        get :filter
      end
      member do
        get :print
      end
    end
    resources :receivable_invoices do
      collection do
        put :update_total
        get :filter
      end
      member do
        get :print
        put :email
      end
    end
    resources :payable_payments do
      member do
        get :print
        get :edit_number
        patch :update_number
      end
      collection do
        put :update_total
      end
    end
    resources :receivable_payments do
      collection do
        put :update_total
      end
    end
    resources :line_items
    resources :payable_line_items
    resources :receivable_line_items
    resources :groups
    resources :categories do
      member do
         get :undelete
      end
    end
    resources :tp_customers do
      member  do
        get :activate
        get :inactivate
        get :delete
        get :undelete
      end
      collection do
        get :inactive
        get :deleted
      end
    end
    resources :tp_vendors do
      member  do
        get :activate
        get :inactivate
        get :delete
        get :undelete
      end
      collection do
        get :inactive
        get :deleted
      end
    end
  end

  namespace :report do
    resources :bases do
      get :postal_mailing, on: :collection
    end

    resources :containers do
      collection do
        get :order_creation
        get :dwelling_perdiem
        get :drops_awaiting_pick_up
        get :pending_empties
        get :pending_loads
        get :operations_without_mark_delivery
        get :confirmed_without_appt_date
        get :pending_tasks
        get :pending_receivables
        get :chassis_invoices
        get :audit_charges
      end
      member do
        get :view_charges
      end
    end
    resources :reconciliations do
      collection do
        put :reconcile_all
        put :calculate_amount
        get :search
        get :to_csv
      end
    end
    resources :companies
    resources :truckers do
      collection do
        get :performance
      end
    end
    resources :customers
    resources :appointments do
      collection do
        get :late
        get :cancelled
      end
    end
    resources :vacations
    resources :driver_payrolls
    resources :audit_charges do
      member do
        get :view
      end
      collection do
        get :unresolved
        get :errors
      end
    end
    resources :maintenances
  end
  resources :bulk_quotes do
    member do
      get :run
    end
  end
  resources :quote_engines do
    collection do
      get :cargo_weight
      get :search
      post :save_charges
    end
  end
  resources :spot_quotes do
    member do
      get :override
    end
    collection do
      put :summary
      get :review
    end
  end
  resources :customer_quotes do
    collection do
      post :quick
    end
  end
  resources :driver_quotes do
    collection do
      post :quick
      post :mail
    end
  end


  resources :rail_roads

  resources :ports do
    resources :rail_roads
  end

  resources :base_rates, only: [:index] do
    collection do
      post :configure
      post :copy
      get :import
      get :export
    end

    member do
      get :sample
    end
  end
  resources :extra_drayages
  resources :discounts

  resources :shipments do
    collection do
      post :email
    end
  end
  resources :fuels
  resources :google_map do
    collection do
      get :new_route
      get :routes
      get :geocode
    end
  end
  resources :addresses do
    collection do
      get :incomplete
    end
  end
  resource :system_setting
  resources :system_logs, only: [:index]
  resources :paper_trails, only: [:index]

  resources :text_messages
  resources :messaging do
    collection do
      get :send_driver_text
      post :send_driver_text
      get :send_driver_email
      post :send_driver_email
      get :send_customer_email
      post :send_customer_email
      get :send_mobile_message
      post :send_mobile_message
      post :forward_sms_to_email
    end
  end

  resources :drug_tests, only: [:index]

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up ''
  # -- just remember to delete public/index.html.
  # connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  resources :default_check_templates

  resources :container_tasks
  resources :task_comments, only: [:show, :create, :update] do
    collection do
      get :popup
    end
  end
  resources :containers do
    collection do
      get :per_order_stack
      get :uninvoiced
      get :pre_alerts
      get :open
      get :cal_date
      get :calendar
      get :multi_calendar
      get :monthly_volume
      get :mileages
      get :daily_volume
      get :wild_search
      get :wild_to_csv
      get :edi
      get :search
    end

    member do
      get :inquire
      get :notify_truckers
      get :reload
      get :lock
      get :unlock
      put :confirm
      get :print
      patch :update_appt_time
      get :embed_appt_time
      put :send_997_reject
      put :send_997_accept
      get :preview
      get :map
      get :preview_quote
      patch :preview_quote
      get :toggle_task
      put :save_charges
    end
    resources :pods, only: [:new, :create, :show]
  end

  resources :chassises do
    collection do
      get :options
      get :charges
      post :audit
    end
    collection do
      get :audit
      get :toggle
    end
  end

  resources :container_selectors, only: [:new, :destroy]

  resources :owners
  resources :states
  resources :support
  resources :crawlers
  resources :companies do
    member do
      put :undelete
      get :choose
    end

    collection do
      get :deleted
      get :search
    end
  end
  resources :customers do
    collection do
      post :matched
    end
    resources :consignees
    resources :shippers
    resources :customers_employees

    member do
      put :undelete
    end

    collection do
      get :deleted
    end
  end

  resources :customers_employees do
    collection do
      get :deleted
    end
    member do
      put :undelete
    end
  end

  resources :truckers do
    member do
      put :undelete
      patch :tasks
    end

    collection do
      get :inactive
      get :export_inactive_to_csv
      get :export_all_to_csv
      get :export_active_to_csv
      get :deleted
      get :expiration_dates
    end
    resources :drug_tests
    resources :day_logs do
      member do
        put :approve
        put :hosv
        patch :reject
      end
    end
  end
  resources :depots do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end
  end

  resources :terminals do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end
  end

  resources :yards do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end
  end

  resources :shippers do
    member do
      put :undelete
    end
    collection do
      get :autocomplete_name
      get :deleted
    end
  end
  resources :consignees do
    member do
      put :undelete
    end
    collection do
      get :autocomplete_name
      get :deleted
    end
  end
  resources :admins do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end
  end
  resources :sslines do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end

    resources :depots
  end

  resources :super_admins do
    member do
      put :undelete
    end
    collection do
      get :deleted
    end
  end
  resources :images do
    member do
      put :approve
      delete :delete
    end
  end
  resources :attachments do
    collection do
      post :upload
    end
  end
  resources :trucks do
    member do
      post :assign
    end
  end
  resources :fuel_purchases
  resources :daily_mileages do
    collection do
      get :report
    end
  end

  resources :import_containers, :shallow => :true do
    member do
      get :notify_truckers
      get :preview
      put :confirm
      get :print
      get :history
      get :calculate_payables
      get :calculate_mileages
      get :preview_quote
      patch :preview_quote
      put :save_charges
    end
    collection do
      get :pre_alerts
    end

    resources :container_operations, :only => [:create]
    resources :import_containers, :only => [:new], :as => "copy_forward"
    resources :payable_container_charges, :only => :index
    resources :receivable_container_charges, :only => :index
  end

  resources :export_containers, :shallow => :true do
    member do
      get :notify_truckers
      get :preview
      put :confirm
      get :print
      get :history
      get :calculate_payables
      get :calculate_receivables
      get :calculate_mileages
      put :save_as_receivables
      get :preview_quote
      patch :preview_quote
      put :save_charges
    end
    collection do
      get :pre_alerts
    end
    resources :container_operations, :only => [:create]
    resources :export_containers, :only => :new, :as => "copy_forward"
    resources :payable_container_charges, :only => :index
    resources :receivable_container_charges, :only => :index
  end

  resources :street_turns, only: [:new, :create] do
    member do
      delete :unlink
    end
  end

  resources :receivable_quotes do
    collection do
      get :query
      patch :cache
    end
  end

  resources :invoices
  resources :payable_invoices do
    collection do
      post :update_total
      get :quick_book
      get :search
      get :autocomplete_number
      get :batch
    end
    member do
      put :update_total_on_edit
      get :print
      get :history
    end
    resources :payable_line_items
  end
  resources :adjustments

  resources :receivable_invoices do
    collection do
      get :quick_book
      post :update_total
      post :emailx
      put :emailx
      get :unemailed
      post :email_all
      get :print_statement
      post :email_statement
      get :autocomplete_number
      get :batch
    end

    member do
      get :print
      put :email
      get :history
      get :preview_210
      put :transmit_by_edi
      put :update_total_on_edit
    end

    resources :receivable_line_items
  end

  resources :payable_payments do
    member do
      get :print
      get :edit_number
      patch :update_number
    end
    collection do
      get :search
      get :uncleared
      get :cleared
      post :set_cleared_date
      get :onfile1099
    end
    resources :line_item_payments
  end
  resources :driver_payrolls, only: [:index, :create] do
    collection do
      put :summary
    end
  end

  resources :receivable_payments do
    collection do
      get :uncleared
      get :cleared
      post :set_cleared_date
    end
    resources :line_item_payments
  end

  resources :users do
    collection do
      get :login
      post :login
    end
  end

  resources :applicants do
    collection do
      get :deleted
      get :status
      get :wizard
      post :wizard
      get :invitation
      put :invitation
    end
    member do
      get :invite
      post :upload
      get :hire
      get :sign
    end
  end

  get 'profile' => 'users#profile'
  get 'unauthorized' => 'errors#unauthorized'
  get 'reports' => 'report/bases#index'
  get 'switch_user' => 'users#switch_user' unless Rails.env.production?
  get 'settings' => 'users#settings'
  get 'my_account' => 'users#my_account'
  get 'email_sent' => 'users#email_sent'
  get 'my_company' => 'companies#me'
  get '/QE', to: redirect('/get_quote.html')
  get '/PODS', to: redirect('/web/containers/pods')

  match 'login', to: 'users#login', via: [:get, :post]
  match 'logout', to: 'users#logout', via: [:get, :delete]
  match 'retrieve_password', to: 'users#retrieve_password', via: [:get, :post]
  match 'set_password', to: 'users#set_password', via: [:get, :post]
  match 'reset_email', to: 'users#reset_email', via: [:get, :post]
  # get ''
  # get '/trackshipment', to: redirect('/trackshipment.html')

  resources :receivable_charges do
    resources :override_receivable_charges
  end
  resources :payable_charges do
    resources :override_payable_charges
  end
  resources :override_receivable_charges
  resources :override_payable_charges
  resources :receivable_container_charges, only: [:new] do
    patch :changed, on: :collection
    post :changed, on: :collection
  end
  resources :payable_container_charges, only: [:new] do
    patch :changed, on: :collection
    post :changed, on: :collection
  end

  resources :roles do
    collection do
      get :edit_action_names
      put :update_action_names
      put :update_all
    end
  end
  resources :rights

  get 'financials',            to: 'financials#index'
  get 'accounts_receivable',   to: 'financials#receivables'
  get 'accounts_payable',      to: 'financials#payables'
  get 'performance_dashboard', to: 'financials#performance_dashboard'
  get 'health_indicator',      to: 'financials#health_indicator'
  get 'mobiles',               to: 'mobiles/base#index'
  # get 'balance_sheet',         to: 'financials#balance_sheet'
  # get 'profit_loss',           to: 'financials#profit_loss'

  resources :customer_credits
  resources :vendor_credits

  resources :messages do
    member do
      get :thank_you
    end
  end
  resources :check_templates do
    collection do
      post :set_default
    end
  end

  # get ':controller/service.wsdl', :action => 'wsdl'

  resources :locations, only: [:index] do
    collection do
      get :track
    end
    member do
      get :map
    end
  end

  resources :categories
  resources :adjustment_categories

  resources :inspections do
    member do
      get :invoiced
      patch :invoiced
      delete :uninvoiced
    end
  end

  resources :cancelled_appointments

  resources :pictures do
    collection do
      get :rotate
    end
  end

  resources :docusigns do
    collection do
      get :psp_returned
      get :sign_returned
    end
  end

  resources :notifications do
    member do
      get :load
      get :reload
      get :deleted
    end
    collection do
      get :toggle
    end
  end

  namespace :api do
    resources :containers
    resources :quotes
  end

  namespace :mobiles do
    resources :users do
      collection do
        get :login
        post :login
        post :logout
        post :retrieve_password
      end
    end
    resources :home do
      collection do
        get :bonus
        get :j1s
      end
    end
    resources :locations
    resources :statuses
    namespace :drivers do
      resources :appointments do
        collection do
          get :late
          get :cancelled
        end
      end
      resources :vacations
      resources :expirations
      resources :performances
      resources :day_logs
      resources :inspections
      resources :maintenances
    end
  end

  namespace :web do
    resources :shipments
    resources :containers do
      member do
        get :charges
        get :elink
        get :pickup
        patch :pickup
      end
      collection do
        get :pods
      end
    end
  end
  # the default route
  root :to => "users#login"
end
