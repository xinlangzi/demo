class Right < ApplicationRecord
  has_and_belongs_to_many :roles
  validates :controller, :action, :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :action, uniqueness: { scope: [:controller] }

  # after_initialize do
  #   self.class.create_functions
  # end

  def self.rights_for_controllers
    new_rights = []
    rights_to_be_destroyed = []

    require Rails.root.to_s + "/app/controllers/application_controller"
    Dir.glob(File.join(Rails.root, "app/controllers/**/*_controller.rb")).each do |file_name|
      require file_name
    end

    pims = ApplicationController.public_instance_methods.map(&:to_s)
    controller_paths = ApplicationController.descendants.map(&:controller_path)
    ApplicationController.descendants.each do |controller|
      # puts "---#{controller.to_s}: #{controller.controller_path}"
      actions = controller.action_methods.map(&:to_s) - pims
      actions.each do |action|
        next if action =~/\A_.+\Z/ # _layout_from_proc
        unless Right.exists?(controller: controller.controller_path, action: action)
          new_rights << Right.new(
            name: "#{controller}.#{action}",
            controller: controller.controller_path,
            action: action
          )
        end
      end

      # Delete obsolete actions
      Right.where(controller: controller.controller_path).each do |right_to_go|
        if !actions.include?(right_to_go.action)
          rights_to_be_destroyed << right_to_go
        end
      end
    end
    # Delete obsolete controllers
    rights_to_be_destroyed+= Right.where.not(controller: controller_paths)

    { new: new_rights, to_be_destroyed: rights_to_be_destroyed }
  end

   # populates the database with actions from each controller. They represent rights to perform an action
  def self.synchronize_with_controllers
    rights = Right.rights_for_controllers
    Right.transaction do
      rights[:new].each do |right|
        puts "adding: #{right.controller} - #{right.action}"
        logger.info "adding: #{right.controller} - #{right.action}"
        right.save!
      end
      rights[:to_be_destroyed].each do |right|
        puts "removing: #{right.controller} - #{right.action}"
        logger.info "removing: #{right.controller} - #{right.action}"
        right.destroy
      end
    end
    rights
  end

  def self.tree
    order('rights.controller, rights.name ASC').group_by(&:controller)
  end

  def allows?(role)
    roles.include?(role)
  end

  def allows=(role)
    roles << role
  end

  # def self.create_functions
  #   Role.all.each do |role|
  #     function_name = "allow_" + role.name.downcase
  #     puts function_name
  #     define_method function_name.to_sym do
  #       allows?(role)
  #     end
  #     function_name = "allow_#{role.name.downcase}="
  #     define_method function_name.to_sym do
  #       allows=(role)
  #     end
  #   end
  # end

end

