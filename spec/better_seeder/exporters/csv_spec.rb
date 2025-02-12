# spec/better_seeder/exporter/csv_exporter_spec.rb
require 'spec_helper'
require 'csv'
require 'tmpdir'

RSpec.describe BetterSeeder::Exporters::Csv do
  let(:dummy_data) do
    [
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
    ]
  end

  around do |example|
    Dir.mktmpdir do |tmpdir|
      BetterSeeder.configure do |config|
        config.preload_path = tmpdir
      end
      example.run
    end
  end

  it 'exports data in CSV format to the correct file' do
    exporter = described_class.new(dummy_data, output_path: 'test_export', table_name: 'users')
    exporter.export

    output_file = exporter.full_output_path
    expect(File).to exist(output_file)

    csv_content = CSV.read(output_file, headers: true)
    # Verify headers match keys from the first record (converted to strings)
    expect(csv_content.headers).to match_array(dummy_data.first.keys.map(&:to_s))
    # Verify that the CSV file contains the same number of data rows
    expect(csv_content.size).to eq(dummy_data.size)

    # Convert CSV rows to an array of hashes for comparison.
    csv_data      = csv_content.map(&:to_h)
    expected_data = dummy_data.map { |h| h.transform_values(&:to_s) }
    expected_data = expected_data.map { |h| h.transform_keys(&:to_s) }
    expect(csv_data).to eq(expected_data)
  end
end
