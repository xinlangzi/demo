class RailsCache

  def self.rebuild_j1s
    Rails.cache.delete(:j1s_number_of_missing)
    Rails.cache.delete(:j1s_number_of_pending)
    J1s.number_of_missing
    J1s.number_of_pending
  end

end