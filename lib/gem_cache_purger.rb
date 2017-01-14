class GemCachePurger
  def initialize(gem_name, version_id)
    @gem_name = gem_name
    @version_id = version_id
  end

  def call
    # We need to purge from Fastly and from Memcached
    purge_compact_index
    purge_deps
    purge_reverse_dep
  end

  private

  attr_reader :gem_name, :version_id

  def purge_reverse_dep
    rubygems = Rubygem.where(id: Dependency.where(version_id: version_id)
      .pluck(:rubygem_id))
      .pluck(:name)
    rubygems.each { |name| Rails.cache.delete("reverse_dep/#{name}") }
  end
  handle_asynchronously :purge_reverse_dep, priority: PRIORITIES[:download]

  def purge_compact_index
    ["info/#{gem_name}", "names"].each do |path|
      Rails.cache.delete(path)
      Fastly.delay.purge(path)
    end

    Fastly.delay.purge("versions")
  end

  def purge_deps
    Rails.cache.delete("deps/v1/#{gem_name}")
  end
end
