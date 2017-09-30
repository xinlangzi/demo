class Picture < Tableless
  attr_accessor :klass, :id, :object, :method

  after_initialize do
    self.object = klass.constantize.unscoped.find(id)
  end

  def rotate!
    uploader.manipulate! do |image|
      image.combine_options do |i|
        i.rotate(90)
      end
      image
    end
    uploader.cache_stored_file!
    uploader.recreate_versions!
    object.save(validate: false)
  end

  def uploader
    @uploader||= object.reload.send(method)
  end

  def url(version=nil)
    version.nil? ? uploader.url : uploader.url(version)
  end
end
