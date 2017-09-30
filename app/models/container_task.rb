class ContainerTask < ApplicationRecord

  validates :name, presence: true, uniqueness: {scope: [:ctype, :acct_type] }
  validates :ctype, presence: true

  scope :import, ->{ where(ctype: "Import") }
  scope :export, ->{ where(ctype: "Export") }
  scope :receivable, ->{ where(acct_type: "Receivable") }
  scope :payable, ->{ where(acct_type: "Payable") }
  scope :others, ->{ where(acct_type: '') }
  scope :accounting, ->{ where("acct_type IS NOT NULL") }

  CONTAINER_TYPES = ["Import", "Export"].freeze
  ACCT_TYPES = ["Receivable", "Payable"].freeze

  def to_s
    str = name
    str+= " (#{acct_type})" unless acct_type.blank?
    str
  end

  def ctype_and_acct_type
    "#{ctype} - #{acct_type}"
  end

  def self.grouped_select
    grouped = all.group_by(&:ctype_and_acct_type)
    grouped.each do |name, objs|
      grouped[name] = objs.map{|obj| [obj.name, obj.id]}
    end
  end

end
