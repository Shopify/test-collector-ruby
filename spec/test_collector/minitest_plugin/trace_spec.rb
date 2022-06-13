# frozen_string_literal: true

require "buildkite/test_collector/minitest_plugin/trace"

RSpec.describe Buildkite::TestCollector::MinitestPlugin::Trace do
  subject(:trace) { Buildkite::TestCollector::MinitestPlugin::Trace.new(result, history: history) }
  let(:result) { double("Result", name: "test_it_passes", test_it_passes: nil, result_code: 'F', failure: failure) }
  let(:failure) { double("Failure", message: "test for invalid character '\xC8'")}
  let(:history) do
    {
      children: [
        {
          start_at: 347611.734956,
          detail: %{"query"=>"SELECT '\xC8'"}
        }
      ]
    }
  end

  context "Location from Trace" do
    before do
      allow(trace).to receive(:source_location) { ["/Users/hello/path/to/your_test.rb", 42] }
    end

    it "returns location from test" do
      prefix = trace.as_hash[:location_prefix]
      result = trace.as_hash[:location]

      expect(prefix).to be_nil
      expect(result).to eq "./Users/hello/path/to/your_test.rb:42"
    end

    it "adds custom location prefix via ENV" do
      env = ENV["BUILDKITE_ANALYTICS_LOCATION_PREFIX"]
      ENV["BUILDKITE_ANALYTICS_LOCATION_PREFIX"] = "payments"

      prefix = trace.as_hash[:location_prefix]
      result = trace.as_hash[:location]

      expect(prefix).to eq "payments"
      expect(result).to eq "payments/Users/hello/path/to/your_test.rb:42"

      ENV["BUILDKITE_ANALYTICS_LOCATION_PREFIX"] = env
    end
  end

  describe '#as_hash' do
    it 'removes invalid UTF-8 characters from top level values' do
      failure_reason = trace.as_hash[:failure_reason]

      expect(failure_reason).to include('test for invalid character')
      expect(failure_reason).to be_valid_encoding
    end

    it 'removes invalid UTF-8 characters from nested values' do
      history_json = trace.as_hash[:history].to_json

      expect(history_json).to include('query')
      expect(history_json).to be_valid_encoding
    end

    it 'does not alter data types which are not strings' do
      history_json = trace.as_hash[:history].to_json

      expect(history_json).to include('347611.734956')
    end

    it "sets the filename, when not in Rails" do
      expect(trace.as_hash[:file_name].split("/").last).to eq("method_double.rb")
    end

    let(:rails) { double("Rails", root: Pathname.new("./")) }
    it "sets the filename, when in Rails" do
      Rails = rails
      expect(trace.as_hash[:file_name].split("/").last).to eq("method_double.rb")
    end
  end
end
