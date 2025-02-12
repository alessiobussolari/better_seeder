# spec/better_seeder/exporter/json_exporter_spec.rb
require 'spec_helper'
require 'json'
require 'tmpdir'

RSpec.describe BetterSeeder::Exporters::Json do
  let(:dummy_data) do
    [
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
    ]
  end

  around do |example|
    Dir.mktmpdir do |tmpdir|
      # Override the preload_path configuration for testing.
      BetterSeeder.configure do |config|
        config.preload_path = tmpdir
      end
      example.run
    end
  end

  it 'exports data in JSON format to the correct file' do
    exporter = described_class.new(dummy_data, output_path: 'test_export', table_name: 'users')
    exporter.export

    output_file = exporter.full_output_path
    expect(File).to exist(output_file)

    exported_data = JSON.parse(File.read(output_file))
    # Manually transform keys of dummy_data from symbols to strings for comparison
    expected_data = dummy_data.map { |h| h.transform_keys(&:to_s) }
    expect(exported_data).to eq(expected_data)
  end
end
