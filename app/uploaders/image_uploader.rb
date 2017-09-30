# encoding: utf-8
class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage Rails.application.secrets.carrierwave["storage"].try(:to_sym)

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process resize_to_limit: [1200, -1], if: :image?

  version :thumb do
    process resize_to_fit: [400, 400], if: :image?
    process thumbnail_pdf: [400, 400], if: :pdf?
    def full_filename(for_file=model.source.file)
      if File.extname(for_file).include?('pdf')
        super.chomp(File.extname(super)) + '.png'
      else
        super(for_file)
      end
    end
  end

  version :pdf, if: :image? do
    process :convert_to_pdf
    process :set_content_type

    def full_filename(for_file)
      ext         = File.extname(for_file)
      base_name   = for_file.chomp(ext)
      "#{base_name}.pdf"
    end

    def set_content_type(*args)
      self.file.instance_variable_set(:@content_type, "application/pdf")
    end

  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w(jpg jpeg gif png pdf tiff tif)
  end

  def pdf_url
    pdf? ? url : pdf.url
  end

  def pdf_path
    pdf? ? path : pdf.path
  end

  def image?(file=self)
    file.content_type.include?('image') rescue false
  end

  def pdf?(file=self)
    file.content_type.include?('pdf') rescue false
  end

  def dimensions
    raise "No Image" unless image?
    @dimensions||= MiniMagick::Image.open(url) rescue MiniMagick::Image.open(path)
  end

  private

    def convert_to_pdf
      width = 0
      height = 0
      manipulate! do |image|
        width = image[:width]
        height = image[:height]
        if width > [height, 540].max
          image.rotate "90"
          width, height = height, width
        end
        image
      end
      Prawn::Document.generate(current_path) do |pdf|
        if (width < 540)&&(height < 720)
          pdf.image open(current_path), position: :center
        else
          pdf.image open(current_path), position: :center, fit: [540, 720]
        end
      end
    end

    def thumbnail_pdf(width, height)
      manipulate! do |img|
        img.format("png") do |c|
          c.trim
          c.resize      "#{width}x#{height}>"
          c.resize      "#{width}x#{height}<"
        end
        img
      end
    end

end
