class Header < ApplicationRecord
  belongs_to :user, foreign_key: :company_id

  def self.for_user(user)
    find_or_create_by(user: user)
  end

  def toggle(key)
    hash = to_hash
    hash[key] = true unless hash.has_key?(key)
    hash[key] = !hash[key]
    update(json: hash.to_json)
  end

  def to_hash
    JSON.parse(self.json || "{}")
  end

  def hidden_columns
    to_hash.select{|k, v| !v}.keys
  end

  def column_visible?(name)
    hidden_columns.exclude?(name)
  end

end