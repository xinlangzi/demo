class SystemLog < ApplicationRecord
  default_scope { order("id desc") }
end
