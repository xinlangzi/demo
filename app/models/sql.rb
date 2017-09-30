class Sql < ApplicationRecord

  scope :yesterday, ->{ where("created_at < ?", 1.day.ago) }

  before_create do
    self.iid = String.random_code
  end

  def self.find(iid)
    self.find_by(iid: iid)
  end

  def self.build(sql)
    clear_expired
    create(statement: sql)
  end

  def self.clear_expired
    Sql.yesterday.destroy_all
  end

  def execute
    Sql.find_by_sql(self.statement)
  end

end