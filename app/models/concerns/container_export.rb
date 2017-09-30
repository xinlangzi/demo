module ContainerExport
  extend ActiveSupport::Concern

  module ClassMethods
    def to_prealert_csv(containers)
      CSV.generate do |csv|
        csv << ["Cont id",
          "Customer",
          "Terminal/ Rail ETA",
          "Terminal",
          "Appointment Date/Time",
          "Rail Last Free Day",
          "Container no",
          "SS Line B/L no"
        ]

        containers.each do |container|
          csv << [
            container.id,
            container.customer.name,
            container.terminal_eta.try(:to_date),
            (container.terminals_info.map(&:name).join('\n') rescue 'N/A'),
            appt_range(container, true),
            container.rail_lfd,
            container.container_no,
            container.ssline_bl_no ? container.ssline_bl_no : container.ssline_booking_no
          ]
        end
      end
    end

    def to_csv(containers, user)
      case user.class.to_s
      when 'SuperAdmin', 'Admin'
        to_csv_by_admin(containers)
      when 'CustomersEmployee'
        to_csv_by_customer(containers, user.customer)
      else raise "Authentication / Access error for #{user.class}"
      end
    end

    def to_drops_awaiting_pickup_csv(containers)
      CSV.generate do |csv|
        csv << [
          "Order Type",
          "Cont id",
          "Date",
          "Container No.",
          "Customer",
          "Consignee/Shipper Name",
          "City",
          "State",
          "Drop Date",
          "Rail Last Free/Cut Off Date"
        ]

        containers.each do |container|
          customers = container.consignees_or_shippers_info
          csv << [
            container._type.upcase[0, 3],
            container.id,
            container.created_at.us_date,
            container.customer.name,
            container.container_no,
            customers.map(&:name).join("\n"),
            customers.map(&:address_city).join("\n"),
            customers.map(&:abbrev).join("\n"),
            container.dropped_date,
            container.is_import? ? container.rail_lfd.try(:ymd) : container.rail_cutoff_date.try(:ymd)
          ]
        end
      end
    end

    def to_pending_empty_csv(containers)
      CSV.generate do |csv|
        csv << [
          "Cont id",
          "Date",
          "Container No.",
          "Customer",
          "Empty Return",
          "Pick Up Date",
          "Rail Last Free Date",
          "Drivers"
        ]

        containers.each do |container|
          csv << [
            container.id,
            container.created_at.us_date,
            container.container_no,
            container.customer.name,
            container.cname,
            container.pick_up_date,
            container.rail_lfd,
            container.trucker_names.join(';')
          ]
        end
      end
    end

    def to_pending_load_csv(containers)
      CSV.generate do |csv|
        csv << [
          "Cont id",
          "Date",
          "Container No.",
          "Customer",
          "Return Load",
          "Pick Up Date",
          "Early Receiving Date",
          "Drivers"
        ]

        containers.each do |container|
          csv << [
            container.id,
            container.created_at.us_date,
            container.container_no,
            container.customer.name,
            container.cname,
            container.pick_up_date,
            container.early_receiving_date,
            container.trucker_names.join(';')
          ]
        end
      end
    end

    private

    def to_csv_by_admin(containers)
      CSV.generate do |csv|
        csv << [
          'ID',
          'Reference No.',
          'Creation Date',
          'Consignee/Shipper(s)',
          'City',
          'State',
          'Container No.',
          'PIN',
          'Terminals',
          'Operations',
          'Trucker(s)',
          'Customer',
          'Invoice(s)',
          'Receivable Amount',
          'Payment(s)',
          'Invoice(s)',
          'Payable Amount',
          'Payment(s)',
          'Admin Comments'
        ]
        containers.each do |container|
          customers = container.consignees_or_shippers_info
          csv << [
            container.id,
            container.reference_no,
            container.created_at.ymd,
            customers.map(&:name).join("\n"),
            customers.map(&:address_city).join("\n"),
            customers.map(&:abbrev).join("\n"),
            container.container_no,
            container.pin,
            container.terminals_info.map(&:name).join("\n"),
            container.operations.map{|o| o.name + ":" + o.view_operated_at.to_s}.join("\n"),
            container.trucker_names.join(';'),
            (container.customer.name rescue 'N/A'),
            container.receivable_invoices.map{|i|i.number}.join(' '),
            container.receivable_container_charges.total_amount,
            container.receivable_payments.map{|p| p.number}.join(' '),
            container.payable_invoices.map{|i| i.number}.join(' '),
            container.payable_container_charges.total_amount,
            container.payable_payments.map{|p| p.number}.join(' '),
            container.admin_comment
          ]
        end
      end
    end

    def to_csv_by_customer(containers, customer)
      CSV.generate do |csv|
        csv << [
          'ID',
          'Reference No.',
          'Consignee/Shipper(s)',
          'City',
          'State',
          'Container No.',
          'Chassis No.',
          'LFD',
          'Terminals',
          'Triaxle',
          'Delivery Date',
          'Time',
          'Payable Amount'
        ]
        containers.each do |container|
          customers = container.consignees_or_shippers_info
          delivered_date = container.delivered_date
          csv << [
            container.id,
            container.reference_no,
            customers.map(&:name).join("\n"),
            customers.map(&:address_city).join("\n"),
            customers.map(&:abbrev).join("\n"),
            container.container_no,
            container.chassis_no,
            container.rail_lfd,
            container.terminals_info.map(&:name).join("\n"),
            (container.triaxle ? 'yes' : 'no'),
            container.delivered_date.try(:ymd),
            container.delivered_date.try(:us_time),
            number_to_currency(container.receivable_container_charges.amount(customer.id))
          ]
        end
      end
    end

  end
end