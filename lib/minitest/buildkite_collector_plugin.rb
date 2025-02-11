module Minitest
  def self.plugin_buildkite_collector_init(options)
    if Buildkite::TestCollector.respond_to?(:uploader)
      self.reporter << Buildkite::TestCollector::MinitestPlugin::Reporter.new(options[:io], options)
    end
  end
end
