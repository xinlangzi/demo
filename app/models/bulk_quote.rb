class BulkQuote < ApplicationRecord
  mount_uploader :csv, CsvUploader

  belongs_to :user

  REQUIRED_COLUMNS =  ['Terminal', 'City', 'State'].freeze
  OPTIONAL_COLUMNS = ['Zip'].freeze

  validate :csv_structure, on: :create
  validates :base_ratio, numericality: { greater_than: 0 }

  def file_exists?
    csv.file.exists? rescue false
  end

  def read_data
    (IO.read(self.csv.path) rescue open(self.csv.url).read).scrub(" ")
  end

  def link_codes
    CSV.parse(read_data)[1..-1].map(&:first).uniq
  end

  def csv_structure
    if self.csv.path.nil?
      errors.add(:base, "The file is not csv please upload again.")
    else
      x = read_data
      csv = CSV.parse(x)
      header_columns = [csv.first[0..2]].join(", ").downcase
      errors.add(:csv, "The header columns of csv file is incorrect.") if header_columns != REQUIRED_COLUMNS.join(", ").downcase
      errors.add(:csv, "You only can request 2000 quotes.") if csv.size > 2001
    end
  end

  def delay_quoting
    self.update_column(:done, false)
    BulkQuote.delay.quoting(id)
  end

  def self.quoting(id)
    bulk_quote = BulkQuote.find(id)
    base_ratio = bulk_quote.base_ratio
    routes = {}
    rows = CSV.parse(bulk_quote.read_data)
    header = rows.shift #header
    grouped_rows = rows.group_by(&:first)
    file_path = bulk_quote.csv_identifier
    CSV.open(file_path, "wb") do |csv|
      csv << header
      has_zip = header.include?("Zip")
      first = 1
      last = has_zip ? 3 : 2
      grouped_rows.each do |code, rows|
        rail_road_id = LinkCode.rail_road(code).try(:id)
        origin = LinkCode.lan_lon(code)
        if origin
          additional_fee = LinkCode.additional_fee(code)
          origins = [origin]
          rows.each_slice(50) do |sliced|
            dests = sliced.map{|row| row[first..last].compact.join(',').gsub(/\s+/,' ') }
            distances = GoogleMap.matrix_distances(origins, dests).first rescue []
            sliced.each_with_index do |row, index|
              meters = distances[index]
              if meters
                quote = SpotQuote.new({ meters: meters*2, dest_address: dests[index], rail_road_id: rail_road_id })
                quote.set_base_rate_fee
                row << (quote.base_rate_fee * base_ratio + additional_fee).round(2)
              end
              csv << row
            end
            sleep(5)
          end
        end
      end
    end
    bulk_quote.csv = File.open(file_path)
    bulk_quote.done = true
    bulk_quote.save!
    File.delete(file_path)
  end

end
