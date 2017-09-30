class ContainerChassis

  def self.build_options(container)
    hub = container.hub
    options = []
    options << ['Terminal', hub.terminals.get_names_and_ids]
    options << ['Depot', container.ssline.depots.get_names_and_ids] if container.ssline
    options
  end

end