module ValidateOperation
  extend ActiveSupport::Concern

  included do
    validate :reasonable_truckers
  end

  def reasonable_truckers
    clusters = build_clusters
    cluster_with_same_driver(clusters)
    maximum_drivers(clusters)
  end

  def build_clusters
    clusters = Clusters.new
    cluster = Cluster.new
    operations.sort_by(&:pos).each do |operation|
      if operation.is_drop? || operation.is_prepull?
        clusters << cluster if cluster.present?
        cluster = Cluster.new
      end
      cluster << operation
    end
    clusters << cluster if cluster.present?
    clusters
  end

  def cluster_with_same_driver(clusters)
    if clusters.live_load?
      errors.add(:base, 'Live load must have the same driver') unless clusters.first.same_driver?
    else
      clusters.each do |cluster|
        unless cluster.same_driver?
          errors.add(:base, 'Operations with a drop must have the same driver') if cluster.drop?
          errors.add(:base, 'Operations after a prepull must have the same driver') if cluster.prepull?
          errors.add(:base, 'Operations before a drop must have the same driver') if cluster.next&&cluster.next.drop?
          errors.add(:base, 'Operations with a prepull must have the same driver') if cluster.next&&cluster.next.prepull?
        end
      end
    end
  end

  def maximum_drivers(clusters)
    maximum = clusters.size
    errors.add(:base, "This container must have maximum of #{maximum} drivers") if operations.map(&:trucker_id).compact.uniq.size > maximum
  end

  class Clusters < Array

    def <<(cluster)
      _last = self.last
      super
      _last.next = self.last if _last
      self.last.prev = _last if _last
    end

    def live_load?
      size == 1
    end

  end

  class Cluster < Array

    attr_accessor :next, :prev

    def same_driver?
      map(&:trucker_id).compact.uniq.size <= 1
    end

    def prepull?
      map(&:is_prepull?).reduce(:|)
    end

    def drop?
      map(&:is_drop?).reduce(:|)
    end

  end

end