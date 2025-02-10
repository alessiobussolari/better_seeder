# spec/better_seeder/exporter/sql_exporter_spec.rb
require "spec_helper"
require "tmpdir"

RSpec.describe BetterSeeder::Exporters::Sql do
  let(:dummy_data) do
    [
      { id: 1, name: "Alice", email: "alice@example.com" },
      { id: 2, name: "Bob", email: "bob@example.com" }
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

  it "exports data in SQL format to the correct file" do
    exporter = described_class.new(dummy_data, output_path: "test_export", table_name: "users")
    exporter.export

    output_file = exporter.full_output_path
    expect(File).to exist(output_file)

    sql_content = File.read(output_file)
    # Check that the SQL file starts with an INSERT statement for the given table
    expect(sql_content).to start_with("INSERT INTO users")
    # Verify that the file contains as many value tuples as there are records.
    # This is a simple check by counting occurrences of '(' that indicate the beginning of a tuple.
    expect(sql_content.scan(/\(/).size - 1).to eq(dummy_data.size)
  end
end
